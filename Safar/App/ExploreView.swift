//
//  ExploreView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-08.
//

import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var userCitiesViewModel: UserCitiesViewModel
    @StateObject private var recommendationsViewModel = RecommendationsViewModel()
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()

    private var visitedCount: Int {
        userCitiesViewModel.visitedCities.count
    }

    private var isUnlocked: Bool {
        visitedCount >= recommendationsViewModel.minimumCitiesRequired
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Explore")
                        .font(.largeTitle)
                        .bold()
                    Spacer()
                }
                .padding(.horizontal)

                recommendationsSection

                leaderboardPreviewSection
            }
            .padding(.vertical)
        }
        .background(Color("Background"))
        .onAppear {
            loadRecommendations()
        }
        .task {
            await leaderboardViewModel.loadTopCities(limit: 5)
            await leaderboardViewModel.loadTopCountries(limit: 5)
            await leaderboardViewModel.loadTopTravelersByCities(limit: 5)
        }
    }

    @ViewBuilder
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recommended for You")
                        .font(.title2)
                        .bold()
                    Text("Powered by Apple Intelligence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isUnlocked && !recommendationsViewModel.isLoading {
                    Button(action: {
                        Task {
                            await recommendationsViewModel.reload(
                                visitedCities: userCitiesViewModel.visitedCities
                            )
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .padding(.horizontal)

            if !isUnlocked {
                lockedStateView
            } else if recommendationsViewModel.isLoading {
                loadingView
            } else if let error = recommendationsViewModel.error {
                errorView(error: error)
            } else if recommendationsViewModel.recommendations.isEmpty {
                emptyView
            } else {
                RecommendationGrid(
                    recommendations: recommendationsViewModel.recommendations
                )
            }
        }
    }

    private var lockedStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.circle")
                .font(.system(size: 44))
                .foregroundColor(.accentColor.opacity(0.6))

            VStack(spacing: 8) {
                Text("Unlock Recommendations")
                    .font(.headline)

                Text("Visit and rate at least 10 cities to get personalized AI recommendations.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 4) {
                Text("\(visitedCount)")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.accentColor)
                Text("/ \(recommendationsViewModel.minimumCitiesRequired) cities")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: Double(visitedCount), total: Double(recommendationsViewModel.minimumCitiesRequired))
                .tint(.accentColor)
                .padding(.horizontal, 40)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Generating recommendations...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    private func errorView(error: RecommendationError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange.opacity(0.7))

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: {
                Task {
                    await recommendationsViewModel.generateRecommendations(
                        visitedCities: userCitiesViewModel.visitedCities
                    )
                }
            }) {
                Text("Try Again")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundColor(Color("Background"))
                    .cornerRadius(20)
            }
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.accentColor.opacity(0.5))
            Text("No recommendations available yet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    private func loadRecommendations() {
        recommendationsViewModel.loadCachedRecommendations()

        if !recommendationsViewModel.hasLoadedFromCache && isUnlocked {
            Task {
                await recommendationsViewModel.generateRecommendations(
                    visitedCities: userCitiesViewModel.visitedCities
                )
            }
        }
    }

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
                    }
                    .buttonStyle(PlainButtonStyle())

                    if city.id != leaderboardViewModel.topCities.prefix(5).last?.id {
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

                NavigationLink(destination: LeaderboardView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(leaderboardViewModel.topCountries.prefix(5)) { country in
                    LeaderboardCountryRow(entry: country)
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                    if country.id != leaderboardViewModel.topCountries.prefix(5).last?.id {
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

                NavigationLink(destination: LeaderboardView()) {
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
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

#Preview {
    ExploreView()
}
