//
//  LeaderboardPersonRow.swift
//  safar
//
//  Row component for displaying a person in the people leaderboard
//

import SwiftUI

enum PeopleRankType {
    case cities
    case countries
}

struct LeaderboardPersonRow: View {
    let entry: PeopleLeaderboardEntry
    let rankBy: PeopleRankType

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Rank badge
            RankBadge(rank: entry.rank ?? 0)

            // User info
            VStack(alignment: .leading, spacing: 2) {
                if let fullName = entry.fullName, !fullName.isEmpty {
                    Text(fullName)
                        .font(.headline)
                        .lineLimit(1)
                } else if let username = entry.username {
                    Text(username)
                        .font(.headline)
                        .lineLimit(1)
                } else {
                    Text("Anonymous")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if let username = entry.username, entry.fullName != nil && !entry.fullName!.isEmpty {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Count display based on rank type
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: rankBy == .cities ? "building.2.fill" : "flag.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 14))
                    Text("\(rankBy == .cities ? entry.visitedCitiesCount : entry.visitedCountriesCount)")
                        .font(.headline)
                        .bold()
                }
                Text(rankBy == .cities ? "cities" : "countries")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack(spacing: 0) {
        LeaderboardPersonRow(
            entry: PeopleLeaderboardEntry(
                id: "1",
                username: "traveler123",
                fullName: "John Doe",
                avatarURL: nil,
                visitedCitiesCount: 42,
                visitedCountriesCount: 15,
                rank: 1
            ),
            rankBy: .cities
        )
        Divider()
        LeaderboardPersonRow(
            entry: PeopleLeaderboardEntry(
                id: "2",
                username: "explorer",
                fullName: "Jane Smith",
                avatarURL: nil,
                visitedCitiesCount: 38,
                visitedCountriesCount: 12,
                rank: 2
            ),
            rankBy: .countries
        )
        Divider()
        LeaderboardPersonRow(
            entry: PeopleLeaderboardEntry(
                id: "3",
                username: "worldtraveler",
                fullName: nil,
                avatarURL: nil,
                visitedCitiesCount: 35,
                visitedCountriesCount: 10,
                rank: 3
            ),
            rankBy: .cities
        )
    }
    .padding()
}
