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
            Text(entry.name)
                .font(.headline)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Visit count display
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.visitCount)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
                Text("^[\(entry.visitCount) visit](inflect: true)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
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
        visitCount: 890,
        rank: 1
    ))
    .padding()
}
