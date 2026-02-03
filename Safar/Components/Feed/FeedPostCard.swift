//
//  FeedPostCard.swift
//  Safar
//
//  Main feed post card composing header, map, places, and interactions
//

import SwiftUI

struct FeedPostCard: View {
    let post: FeedPost
    let onLikeTapped: () -> Void
    let onUserTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with user info and rating
            FeedPostHeader(
                post: post,
                onUserTapped: onUserTapped
            )

            // Mini map with places
            if !post.places.isEmpty {
                FeedPostMap(
                    latitude: post.cityLatitude,
                    longitude: post.cityLongitude,
                    places: post.places
                )
            }

            // Notes/caption
            if let notes = post.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(3)
            }

            // Places disclosure groups
            FeedPlacesSection(places: post.places)

            // Interaction bar (likes, comments)
            FeedInteractionBar(
                likeCount: post.likeCount,
                commentCount: post.commentCount,
                isLiked: post.isLikedByCurrentUser,
                onLikeTapped: onLikeTapped
            )
        }
        .padding(16)
        .background(Color("Background"))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
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
            onUserTapped: {}
        )
        .padding()
    }
    .background(Color(.systemGray6))
}
