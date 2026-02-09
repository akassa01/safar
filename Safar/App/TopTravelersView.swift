//
//  TopTravelersView.swift
//  safar
//
//  Top travelers leaderboard with cities/countries tabs
//

import SwiftUI

enum TravelerTab: String, CaseIterable, Identifiable, IconRepresentable {
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

struct TopTravelersView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    @State private var selectedTab: TravelerTab = .cities

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                TabBarView<TravelerTab>(
                    selectedCategory: $selectedTab,
                    iconSize: 20
                )

                Group {
                    switch selectedTab {
                    case .cities:
                        travelersByCitiesContent
                    case .countries:
                        travelersByCountriesContent
                    }
                }
            }
        }
        .background(Color("Background"))
        .navigationTitle("Top Travelers")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadTopTravelersByCities()
            await viewModel.loadTopTravelersByCountries()
        }
    }

    private var travelersByCitiesContent: some View {
        Group {
            if viewModel.isLoadingPeopleByCities {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if viewModel.topTravelersByCities.isEmpty {
                emptyStateView(message: "No travelers yet")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.topTravelersByCities.enumerated()), id: \.element.id) { index, person in
                        NavigationLink(destination: UserProfileView(userId: person.id)) {
                            LeaderboardPersonRow(entry: person, rankBy: .cities)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < viewModel.topTravelersByCities.count - 1 {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }

    private var travelersByCountriesContent: some View {
        Group {
            if viewModel.isLoadingPeopleByCountries {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if viewModel.topTravelersByCountries.isEmpty {
                emptyStateView(message: "No travelers yet")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.topTravelersByCountries.enumerated()), id: \.element.id) { index, person in
                        NavigationLink(destination: UserProfileView(userId: person.id)) {
                            LeaderboardPersonRow(entry: person, rankBy: .countries)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < viewModel.topTravelersByCountries.count - 1 {
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
            Image(systemName: "person.3")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    NavigationStack {
        TopTravelersView()
    }
}
