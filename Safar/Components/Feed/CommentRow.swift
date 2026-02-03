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

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            AvatarImageView(
                avatarPath: comment.avatarURL,
                size: 36,
                placeholderIconSize: 14
            )

            VStack(alignment: .leading, spacing: 4) {
                // User info and timestamp
                HStack(spacing: 4) {
                    Text(comment.fullName ?? comment.username ?? "Unknown")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if let username = comment.username {
                        Text("@\(username)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("·")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(timeAgoString(from: comment.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Comment content
                Text(comment.content)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            Spacer()

            // Delete button (only for own comments)
            if canDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
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
                createdAt: Date().addingTimeInterval(-3600)
            ),
            canDelete: true,
            onDelete: {}
        )

        CommentRow(
            comment: PostComment(
                id: 2,
                userCityId: 1,
                userId: "456",
                content: "Great recommendations!",
                createdAt: Date().addingTimeInterval(-7200)
            ),
            canDelete: false,
            onDelete: {}
        )
    }
    .padding()
}
