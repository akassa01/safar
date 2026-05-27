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
    let onLikeTapped: () -> Void
    var onReportTapped: (() -> Void)? = nil
    var onBlockTapped: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 16) {
            // Like button
            Button(action: onLikeTapped) {
                HStack(spacing: 4) {
                    Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.subheadline)
                        .foregroundColor(isLiked ? .accentColor : .secondary)

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
            onLikeTapped: {},
            onReportTapped: {},
            onBlockTapped: {}
        )

        FeedInteractionBar(
            likeCount: 0,
            commentCount: 0,
            isLiked: false,
            onLikeTapped: {}
        )
    }
    .padding()
}
