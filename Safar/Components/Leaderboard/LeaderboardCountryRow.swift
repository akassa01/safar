//
//  LeaderboardCountryRow.swift
//  safar
//
//  Row component for displaying a country in the leaderboard
//

import SwiftUI

struct LeaderboardCountryRow: View {
    let entry: CountryLeaderboardEntry

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Rank badge
            RankBadge(rank: entry.rank ?? 0)

            // Country info
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(entry.continent)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Rating display
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 14))
                Text(String(format: "%.1f", entry.averageRating))
                    .font(.headline)
                    .bold()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LeaderboardCountryRow(entry: CountryLeaderboardEntry(
        id: 1,
        name: "Japan",
        continent: "Asia",
        averageRating: 8.9,
        rank: 1
    ))
    .padding()
}
