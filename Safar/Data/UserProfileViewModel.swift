//
//  UserProfileViewModel.swift
//  safar
//
//  ViewModel for viewing another user's profile
//

import Foundation
import SwiftUI

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
    @Published var error: Error?

    private let databaseManager = DatabaseManager.shared
    let userId: String

    /// Whether the current user is viewing their own profile
    var isOwnProfile: Bool {
        guard let currentUserId = databaseManager.getCurrentUserId() else { return false }
        return currentUserId.lowercased() == userId.lowercased()
    }

    init(userId: String) {
        self.userId = userId
    }

    func loadProfile() async {
        isLoading = true
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
            self.error = error
        }

        if isOwnProfile || isFollowing {
            await loadRecentPosts()
        }

        isLoading = false
    }

    func loadRecentPosts() async {
        isLoadingPosts = true
        do {
            recentPosts = try await databaseManager.getUserFeedPosts(userId: userId, limit: 10)
        } catch {
            print("Error loading recent posts: \(error)")
        }
        isLoadingPosts = false
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
            } else {
                try await databaseManager.followUser(followingId: userId)
                isFollowing = true
                followerCount += 1
            }
        } catch {
            self.error = error
        }

        isFollowLoading = false

        // Load or clear recent posts based on follow state
        if isFollowing {
            await loadRecentPosts()
        } else {
            recentPosts = []
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
            } else {
                try await databaseManager.likePost(userCityId: post.id)
            }
        } catch {
            if let revertIndex = recentPosts.firstIndex(where: { $0.id == post.id }) {
                recentPosts[revertIndex].isLikedByCurrentUser = wasLiked
                recentPosts[revertIndex].likeCount += wasLiked ? 1 : -1
            }
            self.error = error
        }
    }

    // Preview cities (top 5 by rating)
    var previewCities: [City] {
        Array(cities.prefix(5))
    }
}
