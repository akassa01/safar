//
//  LeaderboardViewModel.swift
//  safar
//
//  ViewModel for managing leaderboard state (top-rated cities and countries)
//

import Foundation
import SwiftUI

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var topCities: [CityLeaderboardEntry] = []
    @Published var topCountries: [CountryLeaderboardEntry] = []
    @Published var isLoadingCities = false
    @Published var isLoadingCountries = false
    @Published var error: Error?
    @Published var selectedContinent: String?

    private let databaseManager = DatabaseManager.shared

    let continents = ["Africa", "Asia", "Europe", "North America", "Oceania", "South America"]

    func loadTopCities(limit: Int = 50) async {
        isLoadingCities = true
        error = nil

        do {
            if let continent = selectedContinent {
                topCities = try await databaseManager.getTopRatedCitiesByContinent(
                    continent: continent,
                    limit: limit
                )
            } else {
                topCities = try await databaseManager.getTopRatedCities(limit: limit)
            }
        } catch {
            self.error = error
        }

        isLoadingCities = false
    }

    func loadTopCountries(limit: Int = 50) async {
        isLoadingCountries = true
        error = nil

        do {
            topCountries = try await databaseManager.getTopRatedCountries(limit: limit)
        } catch {
            self.error = error
        }

        isLoadingCountries = false
    }

    func refresh() async {
        await loadTopCities()
        await loadTopCountries()
    }

    func selectContinent(_ continent: String?) {
        selectedContinent = continent
        Task {
            await loadTopCities()
        }
    }
}
