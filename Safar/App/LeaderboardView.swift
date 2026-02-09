//
//  LeaderboardView.swift
//  safar
//
//  Top Rated cities and countries leaderboard view
//

import SwiftUI

enum LeaderboardTab: String, CaseIterable, Identifiable, IconRepresentable {
    case cities = "Cities"
    case countries = "Countries"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cities: return "building.2.fill"
        case .countries: return "flag.fill"
        }
    }
}

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    @State private var selectedTab: LeaderboardTab = .cities

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                TabBarView<LeaderboardTab>(
                    selectedCategory: $selectedTab,
                    iconSize: 20
                )

                // TODO: Re-enable continent filters
                // continentFilterView

                // Content
                Group {
                    switch selectedTab {
                    case .cities:
                        cityLeaderboardContent
                    case .countries:
                        countryLeaderboardContent
                    }
                }
            }
        }
        .background(Color("Background"))
        .navigationTitle("Top Rated")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadTopCities()
            await viewModel.loadTopCountries()
        }
    }

    private var continentFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All",
                    isSelected: viewModel.selectedContinent == nil,
                    action: {
                        Task { await viewModel.selectContinent(nil) }
                    }
                )

                ForEach(viewModel.continents, id: \.self) { continent in
                    FilterChip(
                        title: continent,
                        isSelected: viewModel.selectedContinent == continent,
                        action: {
                            Task { await viewModel.selectContinent(continent) }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private var cityLeaderboardContent: some View {
        Group {
            if viewModel.isLoadingCities {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if viewModel.topCities.isEmpty {
                emptyStateView(message: "No rated cities yet")
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.topCities) { city in
                        NavigationLink(destination: CityDetailView(cityId: city.id)) {
                            LeaderboardCityRow(entry: city)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if city.id != viewModel.topCities.last?.id {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }

    private var countryLeaderboardContent: some View {
        Group {
            if viewModel.isLoadingCountries {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if viewModel.topCountries.isEmpty {
                emptyStateView(message: "No rated countries yet")
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.topCountries) { country in
                        NavigationLink(destination: CountryDetailView(country: country)) {
                            LeaderboardCountryRow(entry: country)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if country.id != viewModel.topCountries.last?.id {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }

    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Cities need at least 5 ratings to appear")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    NavigationStack {
        LeaderboardView()
    }
}
