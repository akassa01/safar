//
//  ExploreView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-08.
//

import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var userCitiesViewModel: UserCitiesViewModel
    // @StateObject private var recommendationsViewModel = RecommendationsViewModel()
    @EnvironmentObject var leaderboardViewModel: LeaderboardViewModel

//    private var visitedCount: Int {
//        userCitiesViewModel.visitedCities.count
//    }
//
//    private var isUnlocked: Bool {
//        visitedCount >= recommendationsViewModel.minimumCitiesRequired
//    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // recommendationsSection

                leaderboardPreviewSection
            }
            .padding(.vertical)
        }
        .background(Color("Background"))
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.inline)
//        .onAppear {
//            loadRecommendations()
//        }
        .task {
            if leaderboardViewModel.topCities.isEmpty {
                await leaderboardViewModel.loadTopCities(limit: 5)
                await leaderboardViewModel.loadTopCountries(limit: 5)
                await leaderboardViewModel.loadTopTravelersByCities(limit: 5)
            }
        }
    }

    // MARK: - Recommendations (temporarily disabled)
    // Recommendations section commented out - too unreliable
    //
    // @ViewBuilder
    // private var recommendationsSection: some View { ... }
    // private var lockedStateView: some View { ... }
    // private var loadingView: some View { ... }
    // private func errorView(error: RecommendationError) -> some View { ... }
    // private var emptyView: some View { ... }
    // private func loadRecommendations() { ... }

    // MARK: - Leaderboard Preview Section
    @ViewBuilder
    private var leaderboardPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top Travelers
            if !leaderboardViewModel.topTravelersByCities.isEmpty {
                topTravelersSection
            }

            // Top Rated Cities
            if !leaderboardViewModel.topCities.isEmpty {
                topRatedCitiesSection
            }

            // Top Rated Countries
            if !leaderboardViewModel.topCountries.isEmpty {
                topRatedCountriesSection
            }
        }
    }

    private var topRatedCitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Top Rated Cities")
                        .font(.title2)
                        .bold()
                    Text("Based on community ratings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                NavigationLink(destination: LeaderboardView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(leaderboardViewModel.topCities.prefix(5)) { city in
                    NavigationLink(destination: CityDetailView(cityId: city.id)) {
                        LeaderboardCityRow(entry: city)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    if city.id != leaderboardViewModel.topCities.prefix(5).last?.id {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
            .background(Color("Background"))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var topRatedCountriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Top Rated Countries")
                        .font(.title2)
                        .bold()
                    Text("Based on city averages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                NavigationLink(destination: LeaderboardView(initialTab: .countries)) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(leaderboardViewModel.topCountries.prefix(5)) { country in
                    NavigationLink(destination: CountryDetailView(country: country)) {
                        LeaderboardCountryRow(entry: country)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if country.id != leaderboardViewModel.topCountries.prefix(5).last?.id {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
            .background(Color("Background"))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var topTravelersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Top Travelers")
                        .font(.title2)
                        .bold()
                    Text("Most cities visited")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                NavigationLink(destination: TopTravelersView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(leaderboardViewModel.topTravelersByCities.prefix(5)) { person in
                    NavigationLink(destination: UserProfileView(userId: person.id)) {
                        LeaderboardPersonRow(entry: person, rankBy: .cities)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)

                    if person.id != leaderboardViewModel.topTravelersByCities.prefix(5).last?.id {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
            .background(Color("Background"))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

#Preview {
    ExploreView()
        .environmentObject(LeaderboardViewModel())
}
