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
    let onCityTapped: () -> Void

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
                InlineFlowLayout(spacing: 4) {
                    Button(action: onUserTapped) {
                        Text(post.fullName ?? post.username ?? "Unknown")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)

                    Text("visited")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button(action: onCityTapped) {
                        Text(post.cityName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
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

            // Rating badge (hidden until author has ranked 5+ cities)
            if (post.authorVisitedCitiesCount ?? 0) >= 5, let rating = post.rating {
                RatingCircle(rating: rating, size: 45)
            }
        }
    }

    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

/// A layout that places views inline, wrapping to the next line when needed
private struct InlineFlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        computeLayout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(
            proposal: ProposedViewSize(width: bounds.width, height: bounds.height),
            subviews: subviews
        )
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}

#Preview {
    FeedPostHeader(
        post: FeedPost(
            id: 1,
            userId: "123",
            cityId: 1,
            cityName: "ulaanbataar",
            cityAdmin: "Argentina",
            cityCountry: "Argentina",
            cityLatitude: 35.6762,
            cityLongitude: 139.6503,
            rating: 9.2,
            notes: "Amazing city!",
            visitedAt: Date().addingTimeInterval(-3600)
        ),
        onUserTapped: {},
        onCityTapped: {}
    )
    .padding()
}
