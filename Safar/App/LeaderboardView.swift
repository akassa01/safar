//
//  LeaderboardView.swift
//  safar
//
//  Full-screen leaderboard view with city and country tabs
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
        VStack(spacing: 0) {
            // Tab selector
            TabBarView<LeaderboardTab>(
                selectedCategory: $selectedTab,
                iconSize: 20
            )

            // Continent filter (cities tab only)
            if selectedTab == .cities {
                continentFilterView
            }

            // Content
            Group {
                switch selectedTab {
                case .cities:
                    cityLeaderboardList
                case .countries:
                    countryLeaderboardList
                }
            }
        }
        .background(Color("Background"))
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.refresh()
        }
    }

    private var continentFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All",
                    isSelected: viewModel.selectedContinent == nil,
                    action: { viewModel.selectContinent(nil) }
                )

                ForEach(viewModel.continents, id: \.self) { continent in
                    FilterChip(
                        title: continent,
                        isSelected: viewModel.selectedContinent == continent,
                        action: { viewModel.selectContinent(continent) }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private var cityLeaderboardList: some View {
        Group {
            if viewModel.isLoadingCities {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.topCities.isEmpty {
                emptyStateView(message: "No rated cities yet")
            } else {
                List(viewModel.topCities) { city in
                    NavigationLink(destination: CityDetailView(cityId: city.id)) {
                        LeaderboardCityRow(entry: city)
                    }
                    .listRowBackground(Color("Background"))
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.loadTopCities()
                }
            }
        }
    }

    private var countryLeaderboardList: some View {
        Group {
            if viewModel.isLoadingCountries {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.topCountries.isEmpty {
                emptyStateView(message: "No rated countries yet")
            } else {
                List(viewModel.topCountries) { country in
                    LeaderboardCountryRow(entry: country)
                        .listRowBackground(Color("Background"))
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.loadTopCountries()
                }
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        LeaderboardView()
    }
}
