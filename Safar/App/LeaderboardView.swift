//
//  LeaderboardView.swift
//  safar
//
//  Top Visited cities and countries leaderboard view
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
    @EnvironmentObject var viewModel: LeaderboardViewModel
    @State private var selectedTab: LeaderboardTab

    init(initialTab: LeaderboardTab = .cities) {
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                TabBarView<LeaderboardTab>(
                    selectedCategory: $selectedTab,
                    iconSize: 20
                )

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
        .navigationTitle("Most Visited")
        .navigationBarTitleDisplayMode(.large)
        .task {
            if viewModel.topCities.isEmpty {
                await viewModel.loadTopCities()
                await viewModel.loadTopCountries()
            }
        }
    }

    private var cityLeaderboardContent: some View {
        Group {
            if viewModel.isLoadingCities {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if viewModel.topCities.isEmpty {
                emptyStateView(message: "No visited cities yet")
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
                emptyStateView(message: "No visited countries yet")
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
            Text("Cities need at least 1 visit to appear")
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
            .environmentObject(LeaderboardViewModel())
    }
}
