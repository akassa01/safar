//
//  FriendsWhoVisitedSection.swift
//  Safar
//
//  Section component showing friends who visited a city with "See All" option
//

import SwiftUI

struct FriendsWhoVisitedSection: View {
    let friends: [FriendCityVisit]
    let city: City

    private let maxDisplayedFriends = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Friends Who Visited", icon: "person.2.fill")

            if friends.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 0) {
                    ForEach(friends.prefix(maxDisplayedFriends)) { friend in
                        friendRow(friend)

                        if friend.id != friends.prefix(maxDisplayedFriends).last?.id {
                            Divider()
                        }
                    }

                    if friends.count > maxDisplayedFriends {
                        Divider()
                        seeAllButton
                    }
                }
            }
        }
        .padding()
        .background(Color("Background"))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func friendRow(_ friend: FriendCityVisit) -> some View {
        NavigationLink(destination: CityDetailView(
            cityId: city.id,
            isReadOnly: true,
            city: city,
            externalUserId: friend.userId
        )) {
            HStack(spacing: 12) {
                AvatarImageView(
                    avatarPath: friend.avatarURL,
                    size: 44,
                    placeholderIconSize: 18
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.fullName ?? friend.username ?? "Unknown")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    if let username = friend.username, friend.fullName != nil {
                        Text("@\(username)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if let rating = friend.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private var emptyStateView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "person.2.slash")
                    .font(.title2)
                    .foregroundColor(.secondary.opacity(0.5))
                Text("None of your friends have visited yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }

    private var seeAllButton: some View {
        NavigationLink(destination: FriendsWhoVisitedListView(friends: friends, city: city)) {
            HStack {
                Spacer()
                Text("See all (\(friends.count))")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                Spacer()
            }
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Full List View
struct FriendsWhoVisitedListView: View {
    let friends: [FriendCityVisit]
    let city: City

    var body: some View {
        List {
            ForEach(friends) { friend in
                NavigationLink(destination: CityDetailView(
                    cityId: city.id,
                    isReadOnly: true,
                    city: city,
                    externalUserId: friend.userId
                )) {
                    HStack(spacing: 12) {
                        AvatarImageView(
                            avatarPath: friend.avatarURL,
                            size: 44,
                            placeholderIconSize: 18
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(friend.fullName ?? friend.username ?? "Unknown")
                                .font(.body)
                                .fontWeight(.medium)

                            if let username = friend.username, friend.fullName != nil {
                                Text("@\(username)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if let rating = friend.rating {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", rating))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color("Background"))
            }
        }
        .listStyle(.plain)
        .background(Color("Background"))
        .navigationTitle("Friends Who Visited")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            FriendsWhoVisitedSection(
                friends: [
                    FriendCityVisit(id: "1", userId: "u1", username: "sarah", fullName: "Sarah", avatarURL: nil, rating: 9.2, visitedAt: Date()),
                    FriendCityVisit(id: "2", userId: "u2", username: "mike", fullName: "Mike", avatarURL: nil, rating: 8.1, visitedAt: Date()),
                    FriendCityVisit(id: "3", userId: "u3", username: "alex", fullName: "Alex", avatarURL: nil, rating: 7.5, visitedAt: Date()),
                    FriendCityVisit(id: "4", userId: "u4", username: "emma", fullName: "Emma", avatarURL: nil, rating: 8.8, visitedAt: Date()),
                ],
                city: City(
                    id: 1,
                    displayName: "Tokyo",
                    plainName: "tokyo",
                    admin: "Tokyo",
                    country: "Japan",
                    countryId: 1,
                    population: 13960000,
                    latitude: 35.6762,
                    longitude: 139.6503,
                    visited: nil,
                    rating: nil,
                    notes: nil,
                    userId: nil,
                    averageRating: 8.5,
                    ratingCount: 52
                )
            )
            .padding()
        }
        .background(Color("Background"))
    }
}
