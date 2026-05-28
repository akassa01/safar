//
//  LeaderboardViewModel.swift
//  safar
//
//  ViewModel for managing leaderboard state (most visited cities and countries)
//

import Foundation
import SwiftUI
import os

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var topCities: [CityLeaderboardEntry] = []
    @Published var topCountries: [CountryLeaderboardEntry] = []
    @Published var topTravelersByCities: [PeopleLeaderboardEntry] = []
    @Published var topTravelersByCountries: [PeopleLeaderboardEntry] = []
    @Published var isLoadingCities = false
    @Published var isLoadingCountries = false
    @Published var isLoadingPeopleByCities = false
    @Published var isLoadingPeopleByCountries = false
    @Published var error: Error?
    @Published var selectedContinents: Set<String> = []
    @Published var selectedCountry: String?
    @Published var availableCountries: [String] = []

    private let databaseManager = DatabaseManager.shared

    let continents = ["Africa", "Asia", "Europe", "North America", "Oceania", "South America"]

    var hasActiveFilters: Bool {
        !selectedContinents.isEmpty || selectedCountry != nil
    }

    func loadTopCities(limit: Int = 50) async {
        isLoadingCities = true
        error = nil

        do {
            topCities = try await databaseManager.getMostVisitedCities(
                limit: limit,
                continents: Array(selectedContinents),
                country: selectedCountry
            )
            AnalyticsManager.shared.capture("leaderboard_viewed", properties: [
                "tab": "cities",
                "continent_filter": Array(selectedContinents).joined(separator: ",") as Any,
                "country_filter": selectedCountry as Any
            ])
        } catch {
            self.error = error
            print("Failed to load cities: \(error)")
        }

        isLoadingCities = false
    }

    func loadTopCountries(limit: Int = 50) async {
        isLoadingCountries = true
        error = nil

        do {
            topCountries = try await databaseManager.getMostVisitedCountries(
                limit: limit,
                continents: Array(selectedContinents)
            )
            AnalyticsManager.shared.capture("leaderboard_viewed", properties: [
                "tab": "countries",
                "continent_filter": Array(selectedContinents).joined(separator: ",") as Any
            ])
        } catch {
            self.error = error
            print("Failed to load countries: \(error)")
        }

        isLoadingCountries = false
    }

    func loadAvailableCountries() async {
        do {
            availableCountries = try await databaseManager.getAvailableCountries()
        } catch {
            Log.data.error("loadAvailableCountries failed: \(error)")
        }
    }

    func refresh() async {
        await loadTopCities()
        await loadTopCountries()
        await loadTopTravelersByCities()
        await loadTopTravelersByCountries()
    }

    func toggleContinent(_ continent: String) async {
        if selectedContinents.contains(continent) {
            selectedContinents.remove(continent)
        } else {
            selectedContinents.insert(continent)
        }
        async let cities: () = loadTopCities()
        async let countries: () = loadTopCountries()
        _ = await (cities, countries)
    }

    func selectCountry(_ country: String?) async {
        selectedCountry = country
        async let cities: () = loadTopCities()
        async let countries: () = loadTopCountries()
        _ = await (cities, countries)
    }

    func clearAllFilters() async {
        selectedContinents = []
        selectedCountry = nil
        async let cities: () = loadTopCities()
        async let countries: () = loadTopCountries()
        _ = await (cities, countries)
    }

    func loadTopTravelersByCities(limit: Int = 50) async {
        isLoadingPeopleByCities = true
        error = nil

        do {
            let fetched = try await databaseManager.getTopTravelersByCities(limit: limit)
            topTravelersByCities = BlockManager.shared.filter(fetched, keyPath: \.id)
        } catch {
            Log.data.error("loadTopTravelersByCities failed: \(error)")
            self.error = error
        }

        isLoadingPeopleByCities = false
    }

    func loadTopTravelersByCountries(limit: Int = 50) async {
        isLoadingPeopleByCountries = true
        error = nil

        do {
            let fetched = try await databaseManager.getTopTravelersByCountries(limit: limit)
            topTravelersByCountries = BlockManager.shared.filter(fetched, keyPath: \.id)
        } catch {
            Log.data.error("loadTopTravelersByCountries failed: \(error)")
            self.error = error
        }

        isLoadingPeopleByCountries = false
    }
}
