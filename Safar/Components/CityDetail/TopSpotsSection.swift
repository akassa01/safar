//
//  TopSpotsSection.swift
//  safar
//

import SwiftUI

// MARK: - CategoryFilterChip

struct CategoryFilterChip: View {
    let category: PlaceCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? category.systemColor : Color.secondary.opacity(0.15))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - TopSpotsPlaceRow

struct TopSpotsPlaceRow: View {
    let place: Place
    let onOpenInMaps: (Place) -> Void

    var body: some View {
        Button {
            onOpenInMaps(place)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: place.category.icon)
                    .foregroundColor(place.category.systemColor)
                    .frame(width: 24)

                Text(place.name)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                if place.likes > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text("\(place.likes)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - TopSpotsSection

struct TopSpotsSection: View {
    let allPlaces: [Place]
    @Binding var selectedFilters: Set<PlaceCategory>
    let onOpenInMaps: (Place) -> Void

    private var filteredSortedPlaces: [Place] {
        let base = selectedFilters.isEmpty
            ? allPlaces
            : allPlaces.filter { selectedFilters.contains($0.category) }
        return Array(base.sorted { $0.likes > $1.likes }.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Top Spots", icon: "star.fill")
                Spacer()
                NavigationLink {
                    TopSpotsView(allPlaces: allPlaces, selectedFilters: $selectedFilters)
                } label: {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }

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
                .padding(.horizontal, 1)
            }

            if filteredSortedPlaces.isEmpty {
                Text("No places added yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(filteredSortedPlaces, id: \.localKey) { place in
                        TopSpotsPlaceRow(place: place, onOpenInMaps: onOpenInMaps)
                    }
                }
            }
        }
        .padding()
        .background(Color("Background"))
        .cornerRadius(12)
    }
}
