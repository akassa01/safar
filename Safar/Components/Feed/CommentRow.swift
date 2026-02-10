//
//  CommentRow.swift
//  Safar
//
//  Individual comment display component for post detail view
//

import SwiftUI

struct CommentRow: View {
    let comment: PostComment
    let canDelete: Bool
    let onDelete: () -> Void
    let onReply: () -> Void
    let onToggleLike: () -> Void
    // For replies: closures that take the specific reply
    var onDeleteReply: ((PostComment) -> Void)?
    var onToggleLikeReply: ((PostComment) -> Void)?
    var canDeleteReply: ((PostComment) -> Bool)?
    var isReply: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main comment
            HStack(alignment: .top, spacing: 12) {
                // Avatar
                AvatarImageView(
                    avatarPath: comment.avatarURL,
                    size: isReply ? 28 : 36,
                    placeholderIconSize: isReply ? 11 : 14
                )

                VStack(alignment: .leading, spacing: 4) {
                    // User info and timestamp
                    HStack(spacing: 4) {
                        Text(comment.fullName ?? comment.username ?? "Unknown")
                            .font(isReply ? .caption : .subheadline)
                            .fontWeight(.semibold)

                        if let username = comment.username {
                            Text("@\(username)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Text("·")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(timeAgoString(from: comment.createdAt))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Comment content
                    Text(comment.content)
                        .font(isReply ? .caption : .subheadline)
                        .foregroundColor(.primary)

                    // Action buttons row
                    HStack(spacing: 16) {
                        // Like button
                        Button(action: onToggleLike) {
                            HStack(spacing: 4) {
                                Image(systemName: comment.isLikedByCurrentUser ? "heart.fill" : "heart")
                                    .foregroundColor(comment.isLikedByCurrentUser ? .red : .secondary)
                                if comment.likeCount > 0 {
                                    Text("\(comment.likeCount)")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .font(.caption2)
                        }
                        .buttonStyle(.plain)

                        // Reply button (only on top-level comments)
                        if !isReply {
                            Button(action: onReply) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrowshape.turn.up.left")
                                    Text("Reply")
                                }
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()

                        // Delete button (only for own comments)
                        if canDelete {
                            Button(action: onDelete) {
                                Image(systemName: "trash")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.vertical, 8)

            // Nested replies
            if let replies = comment.replies, !replies.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(replies) { reply in
                        CommentRow(
                            comment: reply,
                            canDelete: canDeleteReply?(reply) ?? false,
                            onDelete: { onDeleteReply?(reply) },
                            onReply: {},
                            onToggleLike: { onToggleLikeReply?(reply) },
                            isReply: true
                        )
                    }
                }
                .padding(.leading, 48)
            }
        }
    }

    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    VStack {
        CommentRow(
            comment: PostComment(
                id: 1,
                userCityId: 1,
                userId: "123",
                content: "This looks amazing! I've been wanting to visit Tokyo for years.",
                createdAt: Date().addingTimeInterval(-3600),
                parentCommentId: nil
            ),
            canDelete: true,
            onDelete: {},
            onReply: {},
            onToggleLike: {}
        )

        CommentRow(
            comment: PostComment(
                id: 2,
                userCityId: 1,
                userId: "456",
                content: "Great recommendations!",
                createdAt: Date().addingTimeInterval(-7200),
                parentCommentId: nil
            ),
            canDelete: false,
            onDelete: {},
            onReply: {},
            onToggleLike: {}
        )
    }
    .padding()
}
