//
//  FeedPlacesSection.swift
//  Safar
//
//  Collapsible places section for feed post cards
//

import SwiftUI

struct FeedPlacesSection: View {
    let places: [Place]

    private var placesByCategory: [PlaceCategory: [Place]] {
        Dictionary(grouping: places, by: { $0.category })
    }

    private var categoriesWithPlaces: [PlaceCategory] {
        PlaceCategory.allCases.filter { placesByCategory[$0]?.isEmpty == false }
    }

    var body: some View {
        if !places.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(categoriesWithPlaces, id: \.self) { category in
                    if let categoryPlaces = placesByCategory[category] {
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(categoryPlaces, id: \.localKey) { place in
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(category.systemColor)
                                            .frame(width: 6, height: 6)

                                        Text(place.name)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)

                                        Spacer()

                                        if let liked = place.liked {
                                            Image(systemName: liked ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                                                .font(.caption)
                                                .foregroundColor(liked ? .green : .red)
                                        }
                                    }
                                    .padding(.leading, 4)
                                }
                            }
                            .padding(.top, 4)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: category.icon)
                                    .font(.caption)
                                    .foregroundColor(category.systemColor)

                                Text("\(category.pluralDisplayName) (\(categoryPlaces.count))")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                        .tint(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    FeedPlacesSection(places: [
        Place(id: 1, name: "Sushi Dai", latitude: 0, longitude: 0, category: .restaurant, liked: true),
        Place(id: 2, name: "Ichiran Ramen", latitude: 0, longitude: 0, category: .restaurant, liked: true),
        Place(id: 3, name: "teamLab Borderless", latitude: 0, longitude: 0, category: .activity),
        Place(id: 4, name: "Park Hyatt", latitude: 0, longitude: 0, category: .hotel, liked: false)
    ])
    .padding()
}
