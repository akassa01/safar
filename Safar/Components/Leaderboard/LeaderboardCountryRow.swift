//
//  LeaderboardCountryRow.swift
//  safar
//
//  Row component for displaying a country in the leaderboard
//

import SwiftUI

struct LeaderboardCountryRow: View {
    let entry: CountryLeaderboardEntry

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

            // Country info
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(entry.continent)
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
        LeaderboardCountryRow(entry: CountryLeaderboardEntry(
            id: 1,
            name: "France",
            continent: "Europe",
            visitCount: 2_150_000,
            rank: 1
        ))
        LeaderboardCountryRow(entry: CountryLeaderboardEntry(
            id: 2,
            name: "Japan",
            continent: "Asia",
            visitCount: 45_200,
            rank: 2
        ))
        LeaderboardCountryRow(entry: CountryLeaderboardEntry(
            id: 3,
            name: "Iceland",
            continent: "Europe",
            visitCount: 890,
            rank: 3
        ))
    }
    .padding()
}
