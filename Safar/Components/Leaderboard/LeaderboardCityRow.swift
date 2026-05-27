//
//  LeaderboardCityRow.swift
//  safar
//
//  Row component for displaying a city in the leaderboard
//

import SwiftUI

struct LeaderboardCityRow: View {
    let entry: CityLeaderboardEntry

    private var formattedCount: String {
        let count = entry.visitCount
        if count >= 1_000_000 {
            let m = Double(count) / 1_000_000
            return String(format: m.truncatingRemainder(dividingBy: 1) == 0 ? "%.0fM" : "%.1fM", m)
        } else if count >= 10_000 {
            let k = Double(count) / 1_000
            return String(format: k.truncatingRemainder(dividingBy: 1) == 0 ? "%.0fK" : "%.1fK", k)
        } else {
            return count.formatted()
        }
    }

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

            // Visit count display
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedCount)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
                Text("visitors")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack {
        LeaderboardCityRow(entry: CityLeaderboardEntry(
            id: 1,
            displayName: "Tokyo",
            admin: "Tokyo",
            country: "Japan",
            visitCount: 1_234_567,
            rank: 1
        ))
        LeaderboardCityRow(entry: CityLeaderboardEntry(
            id: 2,
            displayName: "Paris",
            admin: "Île-de-France",
            country: "France",
            visitCount: 84_500,
            rank: 2
        ))
        LeaderboardCityRow(entry: CityLeaderboardEntry(
            id: 3,
            displayName: "Reykjavik",
            admin: "Capital Region",
            country: "Iceland",
            visitCount: 312,
            rank: 3
        ))
    }
    .padding()
}
