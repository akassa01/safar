//
//  FeedPostHeader.swift
//  Safar
//
//  Header component for feed post cards showing user info and rating
//

import SwiftUI

struct FeedPostHeader: View {
    let post: FeedPost
    let onUserTapped: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Button(action: onUserTapped) {
                AvatarImageView(
                    avatarPath: post.avatarURL,
                    size: 44,
                    placeholderIconSize: 18
                )
            }
            .buttonStyle(.plain)

            // User info and city
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Button(action: onUserTapped) {
                        Text(post.fullName ?? post.username ?? "Unknown")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)

                    Text("visited")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(post.cityName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }

                HStack(spacing: 4) {
                    if let username = post.username {
                        Text("@\(username)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("·")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(timeAgoString(from: post.visitedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Rating badge
            if let rating = post.rating {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", rating))
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
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
    FeedPostHeader(
        post: FeedPost(
            id: 1,
            userId: "123",
            cityId: 1,
            cityName: "Tokyo",
            cityAdmin: "Tokyo",
            cityCountry: "Japan",
            cityLatitude: 35.6762,
            cityLongitude: 139.6503,
            rating: 9.2,
            notes: "Amazing city!",
            visitedAt: Date().addingTimeInterval(-3600)
        ),
        onUserTapped: {}
    )
    .padding()
}
