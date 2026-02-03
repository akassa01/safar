//
//  FeedInteractionBar.swift
//  Safar
//
//  Like and comment interaction bar for feed posts
//

import SwiftUI

struct FeedInteractionBar: View {
    let likeCount: Int
    let commentCount: Int
    let isLiked: Bool
    let onLikeTapped: () -> Void

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

            // Comment count (not a button - entire card navigates to detail)
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
            onLikeTapped: {}
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
