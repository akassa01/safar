//
//  TopSpotsView.swift
//  safar
//

import SwiftUI
import MapKit

struct TopSpotsView: View {
    let allPlaces: [Place]
    @Binding var selectedFilters: Set<PlaceCategory>

    private var filteredSortedPlaces: [Place] {
        let base = selectedFilters.isEmpty
            ? allPlaces
            : allPlaces.filter { selectedFilters.contains($0.category) }
        return base.sorted { $0.likes > $1.likes }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PlaceCategory.allCases) { category in
                            CategoryFilterChip(
                                category: category,
                                isSelected: selectedFilters.contains(category)
                            ) {
                                if selectedFilters.contains(category) {
                                    selectedFilters.remove(category)
                                } else {
                                    selectedFilters.insert(category)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)

                if filteredSortedPlaces.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "star.slash")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No places found")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredSortedPlaces.enumerated()), id: \.element.localKey) { index, place in
                            HStack(spacing: 8) {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .frame(width: 18, alignment: .trailing)
                                TopSpotsPlaceRow(place: place, onOpenInMaps: { _ in openInMaps(place) })
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .background(Color("Background"))
        .navigationTitle("Top Spots")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Maps

    private func openInMaps(_ place: Place) {
        if !place.mapKitId.isEmpty,
           let identifier = MKMapItem.Identifier(rawValue: place.mapKitId) {
            let request = MKMapItemRequest(mapItemIdentifier: identifier)
            Task {
                if let mapItem = try? await request.mapItem {
                    mapItem.openInMaps()
                    return
                }
                openInMapsFallback(place)
            }
        } else {
            openInMapsFallback(place)
        }
    }

    private func openInMapsFallback(_ place: Place) {
        let placemark = MKPlacemark(coordinate: place.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = place.name
        mapItem.openInMaps()
    }
}
