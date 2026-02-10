//
//  FeedViewModel.swift
//  Safar
//
//  Created by Claude on 2026-02-03.
//

import Foundation
import SwiftUI

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [FeedPost] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: Error?
    @Published var hasMorePosts = true

    private let databaseManager = DatabaseManager.shared
    private let pageSize = 20
    private var currentOffset = 0

    /// Load feed posts (initial load or refresh)
    func loadFeed(refresh: Bool = false) async {
        if refresh {
            currentOffset = 0
            hasMorePosts = true
        }

        guard !isLoading else { return }

        if refresh || posts.isEmpty {
            isLoading = true
        }

        error = nil

        do {
            let newPosts = try await databaseManager.getFeedPosts(
                limit: pageSize,
                offset: currentOffset
            )

            if refresh {
                posts = newPosts
            } else {
                posts.append(contentsOf: newPosts)
            }

            hasMorePosts = newPosts.count == pageSize
            currentOffset += newPosts.count
        } catch is CancellationError {
            // Task was cancelled (e.g. view disappeared) — ignore
            return
        } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            // URLSession request cancelled — ignore
            return
        } catch {
            self.error = error
            print("Error loading feed: \(error)")
        }

        isLoading = false
    }

    /// Load more posts when reaching the end of the list
    func loadMoreIfNeeded(currentPost: FeedPost) async {
        guard let lastPost = posts.last,
              currentPost.id == lastPost.id,
              hasMorePosts,
              !isLoadingMore,
              !isLoading else { return }

        isLoadingMore = true
        await loadFeed()
        isLoadingMore = false
    }

    /// Toggle like on a post with optimistic update
    func toggleLike(for post: FeedPost) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }

        let wasLiked = posts[index].isLikedByCurrentUser

        // Optimistic update
        posts[index].isLikedByCurrentUser.toggle()
        posts[index].likeCount += posts[index].isLikedByCurrentUser ? 1 : -1

        do {
            if wasLiked {
                try await databaseManager.unlikePost(userCityId: post.id)
            } else {
                try await databaseManager.likePost(userCityId: post.id)
            }
        } catch {
            // Revert optimistic update on error
            if let revertIndex = posts.firstIndex(where: { $0.id == post.id }) {
                posts[revertIndex].isLikedByCurrentUser = wasLiked
                posts[revertIndex].likeCount += wasLiked ? 1 : -1
            }
            self.error = error
            print("Error toggling like: \(error)")
        }
    }

    /// Update comment count for a post (called after adding/deleting comments)
    func updateCommentCount(for postId: Int64, delta: Int) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].commentCount = max(0, posts[index].commentCount + delta)
        }
    }
}

// MARK: - Post Detail ViewModel
@MainActor
class PostDetailViewModel: ObservableObject {
    @Published var comments: [PostComment] = []
    @Published var likes: [PostLike] = []
    @Published var isLoadingComments = false
    @Published var isLoadingLikes = false
    @Published var isAddingComment = false
    @Published var error: Error?

    private let databaseManager = DatabaseManager.shared
    let post: FeedPost

    init(post: FeedPost) {
        self.post = post
    }

    /// Load comments for the post
    func loadComments() async {
        isLoadingComments = true
        error = nil

        do {
            comments = try await databaseManager.getPostComments(userCityId: post.id)
        } catch {
            self.error = error
            print("Error loading comments: \(error)")
        }

        isLoadingComments = false
    }

    /// Load likes for the post
    func loadLikes() async {
        isLoadingLikes = true

        do {
            likes = try await databaseManager.getPostLikes(userCityId: post.id)
        } catch {
            print("Error loading likes: \(error)")
        }

        isLoadingLikes = false
    }

    /// Add a comment
    func addComment(content: String) async -> Bool {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return false }

        isAddingComment = true
        error = nil

        do {
            let newComment = try await databaseManager.addComment(
                userCityId: post.id,
                content: trimmedContent
            )
            comments.append(newComment)
            isAddingComment = false
            return true
        } catch {
            self.error = error
            print("Error adding comment: \(error)")
            isAddingComment = false
            return false
        }
    }

    /// Delete a comment
    func deleteComment(_ comment: PostComment) async {
        do {
            try await databaseManager.deleteComment(commentId: comment.id)
            comments.removeAll { $0.id == comment.id }
        } catch {
            self.error = error
            print("Error deleting comment: \(error)")
        }
    }

    /// Check if current user can delete a comment
    func canDeleteComment(_ comment: PostComment) -> Bool {
        guard let currentUserId = databaseManager.getCurrentUserId() else { return false }
        return comment.userId == currentUserId
    }
}
