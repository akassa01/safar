//
//  UserProfileViewModel.swift
//  safar
//
//  ViewModel for viewing another user's profile
//

import Foundation
import SwiftUI
import os

@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var cities: [City] = []
    @Published var continentsCount: Int = 0
    @Published var followerCount: Int = 0
    @Published var followingCount: Int = 0
    @Published var isFollowing: Bool = false
    @Published var isLoading = true
    @Published var isFollowLoading = false
    @Published var recentPosts: [FeedPost] = []
    @Published var isLoadingPosts = false
    @Published var isLoadingMorePosts = false
    @Published var hasMorePosts = true
    @Published var error: Error?

    private let databaseManager = DatabaseManager.shared
    private let postsPageSize = 5
    private var postsOffset = 0
    var userId: String
    private var cityDataObserver: NSObjectProtocol?
    private var avatarObserver: NSObjectProtocol?

    /// Whether the current user is viewing their own profile
    var isOwnProfile: Bool {
        guard let currentUserId = databaseManager.getCurrentUserId() else { return false }
        return currentUserId.lowercased() == userId.lowercased()
    }

    init(userId: String = "") {
        self.userId = userId
        cityDataObserver = NotificationCenter.default.addObserver(
            forName: .userCityDataChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.isOwnProfile else { return }
            Task { [weak self] in await self?.loadProfile() }
        }
        avatarObserver = NotificationCenter.default.addObserver(
            forName: .safar_avatarChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self, self.isOwnProfile else { return }
            let newPath = notification.object as? String
            self.profile?.avatarURL = newPath
            self.recentPosts = self.recentPosts.map { var p = $0; p.avatarURL = newPath; return p }
        }
    }

    deinit {
        if let cityDataObserver { NotificationCenter.default.removeObserver(cityDataObserver) }
        if let avatarObserver { NotificationCenter.default.removeObserver(avatarObserver) }
    }

    func loadCurrentUserProfile() async {
        guard let currentUserId = databaseManager.getCurrentUserId() else { return }
        userId = currentUserId
        await loadProfile()
    }

    func clearData() {
        userId = ""
        profile = nil
        cities = []
        continentsCount = 0
        followerCount = 0
        followingCount = 0
        isFollowing = false
        recentPosts = []
        postsOffset = 0
        hasMorePosts = true
        isLoading = true
    }

    func loadProfile() async {
        isLoading = profile == nil
        error = nil

        do {
            // Load profile, cities, follow counts, and follow status in parallel
            async let profileTask = databaseManager.getUserProfile(userId: userId)
            async let citiesTask = databaseManager.getVisitedCitiesForUser(userId: userId)
            async let continentsTask = databaseManager.getContinentsCountForUser(userId: userId)
            async let followCountsTask = databaseManager.getFollowCounts(userId: userId)
            async let isFollowingTask = databaseManager.isFollowing(userId: userId)

            let (profile, cities, continents, counts, following) = try await (
                profileTask,
                citiesTask,
                continentsTask,
                followCountsTask,
                isFollowingTask
            )

            self.profile = profile
            self.cities = cities.sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
            self.continentsCount = continents
            self.followerCount = counts.followers
            self.followingCount = counts.following
            self.isFollowing = following
        } catch {
            Log.data.error("loadProfile failed for userId \(self.userId): \(error)")
            self.error = error
        }

        if isOwnProfile || isFollowing {
            await loadRecentPosts(refresh: true)
        }

        isLoading = false
    }

    func loadRecentPosts(refresh: Bool = false) async {
        if refresh {
            postsOffset = 0
            hasMorePosts = true
        }

        isLoadingPosts = recentPosts.isEmpty

        do {
            let newPosts = try await databaseManager.getUserFeedPosts(
                userId: userId,
                limit: postsPageSize,
                offset: postsOffset
            )

            if refresh {
                recentPosts = newPosts
            } else if postsOffset == 0 {
                recentPosts = newPosts
            } else {
                recentPosts.append(contentsOf: newPosts)
            }

            hasMorePosts = newPosts.count == postsPageSize
            postsOffset += newPosts.count
        } catch {
            Log.data.error("loadRecentPosts failed for userId \(self.userId): \(error)")
        }

        isLoadingPosts = false
    }

    func loadMorePostsIfNeeded(currentPost: FeedPost) async {
        guard let lastPost = recentPosts.last,
              currentPost.id == lastPost.id,
              hasMorePosts,
              !isLoadingMorePosts,
              !isLoadingPosts else { return }

        isLoadingMorePosts = true
        await loadRecentPosts()
        isLoadingMorePosts = false
    }

    func toggleFollow() async {
        // Prevent self-following
        guard !isOwnProfile else { return }

        isFollowLoading = true

        do {
            if isFollowing {
                try await databaseManager.unfollowUser(followingId: userId)
                isFollowing = false
                followerCount = max(0, followerCount - 1)
                AnalyticsManager.shared.capture("user_unfollowed", properties: ["unfollowed_user_id": userId])
            } else {
                try await databaseManager.followUser(followingId: userId)
                isFollowing = true
                followerCount += 1
                AnalyticsManager.shared.capture("user_followed", properties: ["followed_user_id": userId])
            }
        } catch {
            Log.data.error("toggleFollow failed for userId \(self.userId): \(error)")
            self.error = error
        }

        isFollowLoading = false

        // Load or clear recent posts based on follow state
        if isFollowing {
            await loadRecentPosts(refresh: true)
        } else {
            recentPosts = []
            postsOffset = 0
            hasMorePosts = true
        }
    }

    func toggleLike(for post: FeedPost) async {
        guard let index = recentPosts.firstIndex(where: { $0.id == post.id }) else { return }

        let wasLiked = recentPosts[index].isLikedByCurrentUser

        recentPosts[index].isLikedByCurrentUser.toggle()
        recentPosts[index].likeCount += recentPosts[index].isLikedByCurrentUser ? 1 : -1

        do {
            if wasLiked {
                try await databaseManager.unlikePost(userCityId: post.id)
                AnalyticsManager.shared.capture("post_unliked", properties: ["post_id": post.id])
            } else {
                try await databaseManager.likePost(userCityId: post.id)
                AnalyticsManager.shared.capture("post_liked", properties: [
                    "post_id": post.id,
                    "author_id": post.userId
                ])
            }
        } catch {
            if let revertIndex = recentPosts.firstIndex(where: { $0.id == post.id }) {
                recentPosts[revertIndex].isLikedByCurrentUser = wasLiked
                recentPosts[revertIndex].likeCount += wasLiked ? 1 : -1
            }
            Log.data.error("toggleLike failed for post \(post.id): \(error)")
            self.error = error
        }
    }

    // Preview cities (top 5 by rating)
    var previewCities: [City] {
        Array(cities.prefix(5))
    }
}
