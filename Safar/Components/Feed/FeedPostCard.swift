//
//  FeedPostCard.swift
//  Safar
//
//  Main feed post card composing header, map, places, and interactions.
//  Pass onReportPostTapped / onBlockUserTapped to show the ... overflow menu.
//

import SwiftUI

struct FeedPostCard: View {
    let post: FeedPost
    let onLikeTapped: () -> Void
    let onUserTapped: () -> Void
    let onCityTapped: () -> Void
    let onPostTapped: () -> Void
    var isVisited: Bool = false
    var onBookmarkTapped: (() -> Void)? = nil
    var onReportPostTapped: (() -> Void)? = nil
    var onBlockUserTapped: (() -> Void)? = nil

    var body: some View {
        Button(action: onPostTapped) {
            VStack(alignment: .leading, spacing: 12) {
                // Header row: user info + bookmark button (top right)
                HStack(alignment: .top, spacing: 12) {
                    FeedPostHeader(
                        post: post,
                        onUserTapped: onUserTapped,
                        onCityTapped: onCityTapped
                    )

                    Spacer(minLength: 4)

                    // Bookmark / visited indicator
                    if onBookmarkTapped != nil {
                        if isVisited {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        } else {
                            Button {
                                onBookmarkTapped?()
                            } label: {
                                Image(systemName: post.isCityInUserList ? "bookmark.fill" : "bookmark")
                                    .font(.title2)
                                    .foregroundColor(post.isCityInUserList ? .accentColor : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Map with places
                CityMapView(
                    latitude: post.cityLatitude,
                    longitude: post.cityLongitude,
                    places: post.places,
                    height: 150,
                    isInteractive: false
                )

                // Notes/caption
                if let notes = post.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }

                // Places disclosure groups
                FeedPlacesSection(places: post.places)

                // Interaction bar (likes, comments, optional ... menu)
                FeedInteractionBar(
                    likeCount: post.likeCount,
                    commentCount: post.commentCount,
                    isLiked: post.isLikedByCurrentUser,
                    onLikeTapped: onLikeTapped,
                    onReportTapped: onReportPostTapped,
                    onBlockTapped: onBlockUserTapped
                )
            }
            .padding(16)
            .background(Color("Background"))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.1), lineWidth: 1))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScrollView {
        FeedPostCard(
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
                notes: "Absolutely loved Tokyo! The food was incredible and the culture was fascinating. Can't wait to go back!",
                visitedAt: Date().addingTimeInterval(-7200)
            ),
            onLikeTapped: {},
            onUserTapped: {},
            onCityTapped: {},
            onPostTapped: {},
            onReportPostTapped: {},
            onBlockUserTapped: {}
        )
        .padding()
    }
    .background(Color(.systemGray6))
}
