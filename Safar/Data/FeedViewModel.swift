//
//  FeedViewModel.swift
//  Safar
//
//  Created by Claude on 2026-02-03.
//

import Foundation
import SwiftUI
import os

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
            Log.data.error("loadFeed failed: \(error)")
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
            Log.data.error("toggleLike failed for post \(post.id): \(error)")
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
    @Published var replyingTo: PostComment?
    @Published var error: Error?

    private let databaseManager = DatabaseManager.shared
    let post: FeedPost

    init(post: FeedPost) {
        self.post = post
    }

    /// Load comments for the post (returns threaded top-level comments with replies nested)
    func loadComments() async {
        isLoadingComments = true
        error = nil

        do {
            comments = try await databaseManager.getPostComments(userCityId: post.id)
        } catch {
            self.error = error
            Log.data.error("loadComments failed for post \(self.post.id): \(error)")
        }

        isLoadingComments = false
    }

    /// Load likes for the post
    func loadLikes() async {
        isLoadingLikes = true

        do {
            likes = try await databaseManager.getPostLikes(userCityId: post.id)
        } catch {
            Log.data.error("loadLikes failed for post \(self.post.id): \(error)")
        }

        isLoadingLikes = false
    }

    /// Add a comment (or reply if replyingTo is set)
    func addComment(content: String) async -> Bool {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return false }

        isAddingComment = true
        error = nil

        let parentId = replyingTo?.id

        do {
            let newComment = try await databaseManager.addComment(
                userCityId: post.id,
                content: trimmedContent,
                parentCommentId: parentId
            )

            if let parentId = parentId {
                // Append reply under the parent comment
                if let parentIndex = comments.firstIndex(where: { $0.id == parentId }) {
                    if comments[parentIndex].replies == nil {
                        comments[parentIndex].replies = []
                    }
                    comments[parentIndex].replies?.append(newComment)
                }
            } else {
                // Append as a new top-level comment
                comments.append(newComment)
            }

            replyingTo = nil
            isAddingComment = false
            return true
        } catch {
            self.error = error
            Log.data.error("addComment failed for post \(self.post.id): \(error)")
            isAddingComment = false
            return false
        }
    }

    /// Delete a comment (handles both top-level and replies)
    func deleteComment(_ comment: PostComment) async {
        do {
            try await databaseManager.deleteComment(commentId: comment.id)

            if let parentId = comment.parentCommentId {
                // Remove from parent's replies
                if let parentIndex = comments.firstIndex(where: { $0.id == parentId }) {
                    comments[parentIndex].replies?.removeAll { $0.id == comment.id }
                }
            } else {
                // Remove top-level comment (and its replies cascade on the DB side)
                comments.removeAll { $0.id == comment.id }
            }
        } catch {
            self.error = error
            Log.data.error("deleteComment failed for comment \(comment.id): \(error)")
        }
    }

    /// Toggle like on a comment with optimistic update
    func toggleCommentLike(for comment: PostComment) async {
        // Find the comment in top-level or replies
        let wasLiked = comment.isLikedByCurrentUser

        // Optimistic update
        updateCommentLikeState(commentId: comment.id, isLiked: !wasLiked, likeDelta: wasLiked ? -1 : 1)

        do {
            if wasLiked {
                try await databaseManager.unlikeComment(commentId: comment.id)
            } else {
                try await databaseManager.likeComment(commentId: comment.id)
            }
        } catch {
            // Revert on error
            updateCommentLikeState(commentId: comment.id, isLiked: wasLiked, likeDelta: wasLiked ? 1 : -1)
            Log.data.error("toggleCommentLike failed for comment \(comment.id): \(error)")
        }
    }

    /// Helper to update like state in the nested comment structure
    private func updateCommentLikeState(commentId: Int64, isLiked: Bool, likeDelta: Int) {
        for i in 0..<comments.count {
            if comments[i].id == commentId {
                comments[i].isLikedByCurrentUser = isLiked
                comments[i].likeCount = max(0, comments[i].likeCount + likeDelta)
                return
            }
            if let replies = comments[i].replies {
                for j in 0..<replies.count {
                    if replies[j].id == commentId {
                        comments[i].replies?[j].isLikedByCurrentUser = isLiked
                        comments[i].replies?[j].likeCount = max(0, replies[j].likeCount + likeDelta)
                        return
                    }
                }
            }
        }
    }

    /// Check if current user can delete a comment
    func canDeleteComment(_ comment: PostComment) -> Bool {
        guard let currentUserId = databaseManager.getCurrentUserId() else { return false }
        return comment.userId == currentUserId
    }

    /// Total comment count (top-level + all replies)
    var totalCommentCount: Int {
        comments.reduce(0) { $0 + 1 + ($1.replies?.count ?? 0) }
    }
}
