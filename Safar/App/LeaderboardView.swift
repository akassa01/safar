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
        ScrollView {
            VStack(spacing: 0) {
                // People leaderboard section (separate from tabs)
                peopleLeaderboardSection

                Divider()
                    .padding(.horizontal)
                    .padding(.vertical, 16)

                // Tab selector for Cities/Countries by rating
                VStack(spacing: 0) {
                    Text("Top Rated")
                        .font(.title2)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.bottom, 8)

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
                            cityLeaderboardContent
                        case .countries:
                            countryLeaderboardContent
                        }
                    }
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

    // MARK: - People Leaderboard Section

    private var peopleLeaderboardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Travelers")
                .font(.title2)
                .bold()
                .padding(.horizontal)

            // Most Cities Visited
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(.accentColor)
                    Text("Most Cities Visited")
                        .font(.headline)
                }
                .padding(.horizontal)

                if viewModel.isLoadingPeopleByCities {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else if viewModel.topTravelersByCities.isEmpty {
                    Text("No travelers yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.topTravelersByCities.prefix(5).enumerated()), id: \.element.id) { index, person in
                            LeaderboardPersonRow(entry: person, rankBy: .cities)
                                .padding(.horizontal)
                                .padding(.vertical, 8)

                            if index < min(4, viewModel.topTravelersByCities.count - 1) {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }

            // Most Countries Visited
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.accentColor)
                    Text("Most Countries Visited")
                        .font(.headline)
                }
                .padding(.horizontal)

                if viewModel.isLoadingPeopleByCountries {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else if viewModel.topTravelersByCountries.isEmpty {
                    Text("No travelers yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.topTravelersByCountries.prefix(5).enumerated()), id: \.element.id) { index, person in
                            LeaderboardPersonRow(entry: person, rankBy: .countries)
                                .padding(.horizontal)
                                .padding(.vertical, 8)

                            if index < min(4, viewModel.topTravelersByCountries.count - 1) {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
        }
        .padding(.top)
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
                        LeaderboardCountryRow(entry: country)
                            .padding(.horizontal)
                            .padding(.vertical, 8)

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
