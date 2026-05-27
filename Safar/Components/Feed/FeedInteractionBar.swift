//
//  FeedInteractionBar.swift
//  Safar
//
//  Like, comment, and bookmark interaction bar for feed posts.
//  Optional report/block callbacks show a ... menu on the trailing edge.
//

import SwiftUI

struct FeedInteractionBar: View {
    let likeCount: Int
    let commentCount: Int
    let isLiked: Bool
    let isBookmarked: Bool
    /// True when the city is already in the visited list — bookmark shows filled but is non-interactive.
    var isVisited: Bool = false
    let onLikeTapped: () -> Void
    var onBookmarkTapped: (() -> Void)? = nil
    var onReportTapped: (() -> Void)? = nil
    var onBlockTapped: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 16) {
            // Like button
            Button(action: onLikeTapped) {
                HStack(spacing: 4) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.subheadline)
                        .foregroundColor(isLiked ? .red : .secondary)

                    if likeCount > 0 {
                        Text("\(likeCount)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            // Comment count (not a button — entire card navigates to detail)
            HStack(spacing: 4) {
                Image(systemName: "bubble.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if commentCount > 0 {
                    Text("\(commentCount)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Bookmark button — filled when city is in user's list, disabled if already visited
            Button {
                guard !isVisited else { return }
                onBookmarkTapped?()
            } label: {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.subheadline)
                    .foregroundColor(isBookmarked ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(isVisited)

            // Overflow menu (report / block) — only shown for other users' posts
            if onReportTapped != nil || onBlockTapped != nil {
                Menu {
                    if let onReport = onReportTapped {
                        Button {
                            onReport()
                        } label: {
                            Label("Report Post", systemImage: "exclamationmark.bubble")
                        }
                    }
                    if let onBlock = onBlockTapped {
                        Button(role: .destructive) {
                            onBlock()
                        } label: {
                            Label("Block User", systemImage: "hand.raised")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    VStack(spacing: 20) {
        FeedInteractionBar(
            likeCount: 12,
            commentCount: 3,
            isLiked: true,
            isBookmarked: false,
            onLikeTapped: {},
            onBookmarkTapped: {},
            onReportTapped: {},
            onBlockTapped: {}
        )

        FeedInteractionBar(
            likeCount: 0,
            commentCount: 0,
            isLiked: false,
            isBookmarked: true,
            onLikeTapped: {},
            onBookmarkTapped: {}
        )

        FeedInteractionBar(
            likeCount: 5,
            commentCount: 1,
            isLiked: false,
            isBookmarked: true,
            isVisited: true,
            onLikeTapped: {}
        )
    }
    .padding()
}
