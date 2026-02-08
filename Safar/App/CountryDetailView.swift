//
//  CountryDetailView.swift
//  safar
//
//  Country detail view showing rating, rank, and top cities
//

import SwiftUI

struct CountryDetailView: View {
    let country: CountryLeaderboardEntry

    @State private var topCities: [CityLeaderboardEntry] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private static let minimumRatingsForDisplay = 5

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading country details...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("Background"))
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        headerSection

                        if !topCities.isEmpty {
                            topCitiesSection
                        } else {
                            emptyCitiesView
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color("Background"))
            }
        }
        .navigationTitle(country.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("Background"))
        .background(Color("Background"))
        .task {
            await loadTopCities()
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        CountryBannerView(
            countryId: country.id,
            countryName: country.name,
            rating: country.averageRating,
            rank: country.rank
        )
    }

    private var topCitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
        	SectionHeader(title: "Top Cities", icon: "building.2.fill")
            .padding(.horizontal)
            .padding(.top, 20)

            VStack(spacing: 0) {
                ForEach(topCities) { city in
                    NavigationLink(destination: CityDetailView(cityId: city.id)) {
                        CountryCityRow(entry: city)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)

                    if city.id != topCities.last?.id {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }

    private var emptyCitiesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.2")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No top-rated cities yet")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Cities need at least 5 ratings to appear here")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func loadTopCities() async {
        isLoading = true
        errorMessage = nil

        do {
            let cities = try await DatabaseManager.shared.getTopCitiesForCountry(
                countryName: country.name,
                limit: 50
            )
            await MainActor.run {
                self.topCities = cities
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// MARK: - Supporting Views

struct CountryRankBadge: View {
    let rank: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "number")
                .font(.system(size: 12, weight: .bold))
            Text("\(rank)")
                .font(.system(size: 16, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.orange)
                .shadow(color: .orange.opacity(0.4), radius: 4, x: 0, y: 2)
        )
    }
}

struct CountryCityRow: View {
    let entry: CityLeaderboardEntry

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Rank badge
            RankBadge(rank: entry.rank ?? 0)

            // City info
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(entry.admin)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Rating display
            RatingCircle(rating: entry.averageRating, size: 35)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        CountryDetailView(country: CountryLeaderboardEntry(
            id: 1,
            name: "Japan",
            continent: "Asia",
            averageRating: 8.9,
            rank: 1
        ))
    }
}
