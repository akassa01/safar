//
//  FriendsWhoVisitedSection.swift
//  Safar
//
//  Section component showing friends who visited a city with "See All" option
//

import SwiftUI

// MARK: - Friend City Visit Model
/// Represents a friend's visit to a city
struct FriendCityVisit: Identifiable {
    let id: String  // user_city.id as string for Identifiable
    let userId: String
    let username: String?
    let fullName: String?
    let avatarURL: String?
    let rating: Double?
    let visitedAt: Date?
    let notes: String?
}

// MARK: - Friends Who Visited Content
struct FriendsWhoVisitedContent: View {
    let friends: [FriendCityVisit]
    let city: City

    private let maxDisplayedFriends = 3

    var body: some View {
        if friends.isEmpty {
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
        }
    }

    @ViewBuilder
    private func friendRow(_ friend: FriendCityVisit) -> some View {
        NavigationLink(destination: FriendPostView(friend: friend, city: city)) {
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
                    RatingCircle(rating: rating, size: 35)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Friend Post Wrapper
/// Loads places + social data, then shows PostDetailView
struct FriendPostView: View {
    let friend: FriendCityVisit
    let city: City
    @StateObject private var feedViewModel = FeedViewModel()
    @State private var post: FeedPost
    @State private var isLoading = true

    init(friend: FriendCityVisit, city: City) {
        self.friend = friend
        self.city = city
        self._post = State(initialValue: FeedPost(from: friend, city: city))
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                PostDetailView(post: post, feedViewModel: feedViewModel)
            }
        }
        .background(Color("Background"))
        .task {
            // Load places
            if let userId = UUID(uuidString: friend.userId) {
                if let places = try? await DatabaseManager.shared.getUserPlaces(userId: userId, cityId: city.id) {
                    post.places = places
                }
            }

            // Load social data
            if let social = try? await DatabaseManager.shared.getPostSocialData(userCityId: post.id) {
                post.likeCount = social.likeCount
                post.commentCount = social.commentCount
                post.isLikedByCurrentUser = social.isLiked
            }

            feedViewModel.posts = [post]
            isLoading = false
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
                NavigationLink(destination: FriendPostView(friend: friend, city: city)) {
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
                            RatingCircle(rating: rating, size: 35)
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
            FriendsWhoVisitedContent(
                friends: [
                    FriendCityVisit(id: "1", userId: "u1", username: "sarah", fullName: "Sarah", avatarURL: nil, rating: 9.2, visitedAt: Date(), notes: nil),
                    FriendCityVisit(id: "2", userId: "u2", username: "mike", fullName: "Mike", avatarURL: nil, rating: 8.1, visitedAt: Date(), notes: nil),
                    FriendCityVisit(id: "3", userId: "u3", username: "alex", fullName: "Alex", avatarURL: nil, rating: 7.5, visitedAt: Date(), notes: nil),
                    FriendCityVisit(id: "4", userId: "u4", username: "emma", fullName: "Emma", avatarURL: nil, rating: 8.8, visitedAt: Date(), notes: nil),
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
