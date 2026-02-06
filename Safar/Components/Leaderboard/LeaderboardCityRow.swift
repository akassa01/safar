//
//  LeaderboardCityRow.swift
//  safar
//
//  Row component for displaying a city in the leaderboard
//

import SwiftUI

struct LeaderboardCityRow: View {
    let entry: CityLeaderboardEntry

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Rank badge
            RankBadge(rank: entry.rank ?? 0)

            // City info
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(entry.admin), \(entry.country)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Rating display
            VStack(alignment: .trailing, spacing: 2) {
                RatingCircle(rating: entry.averageRating, size: 35)
                Text("\(entry.ratingCount) ratings")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LeaderboardCityRow(entry: CityLeaderboardEntry(
        id: 1,
        displayName: "Tokyo",
        admin: "Tokyo",
        country: "Japan",
        averageRating: 9.2,
        ratingCount: 1234,
        rank: 1
    ))
    .padding()
}
