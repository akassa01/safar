import Foundation
import SwiftUI
import Supabase
import os

@MainActor
class UserCitiesViewModel: ObservableObject {
    @Published var visitedCities: [City] = []
    @Published var bucketListCities: [City] = []
    @Published var allUserCities: [City] = []
    @Published var visitedCountries: [String] = []
    @Published var visitedContinents: [String] = []
    @Published var visitedCitiesCount: Int = 0
    @Published var visitedCountriesCount: Int = 0
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isOfflineData = false
    
    private let databaseManager = DatabaseManager.shared
    private var _currentUserId: UUID?
    var wantCountries:Bool = true
    
    // Expose currentUserId for external access
    var currentUserId: UUID? {
        return _currentUserId
    }
    
    func setUserId(_ userId: UUID) {
        self._currentUserId = userId
           Task {
               await loadUserData()
           }
    }
    
    func initializeWithCurrentUser() async {
        do {
            print("Initializing current user data..." )
            let user = try await databaseManager.getCurrentUser()
            self._currentUserId = user.id
            print("Current user id: \(user.id)")
            // Await data load directly instead of spawning a detached Task
            await loadUserData()
        } catch {
            Log.auth.error("initializeWithCurrentUser failed: \(error)")
            self.error = error
        }
    }

    func clearUserData(clearCache: Bool = false) {
        if clearCache, let userId = _currentUserId {
            CityCacheManager.shared.clearCache(for: userId)
        }
        _currentUserId = nil
        visitedCities = []
        bucketListCities = []
        allUserCities = []
        visitedCountries = []
        visitedContinents = []
        visitedCitiesCount = 0
        visitedCountriesCount = 0
        error = nil
        isOfflineData = false
    }

    func loadUserData() async {
        print("Checking user id")
        guard let userId = _currentUserId else { return }

        print("Getting user data")
        isLoading = true
        error = nil
        isOfflineData = false

        let isOnline = NetworkMonitor.shared.isConnected

        if isOnline {
            do {
                let cities = try await getUserCitiesWithDetails(userId: userId)
                print(cities.count)
                for city in cities {
                    print("user city: \(city.displayName)")
                }

                self.allUserCities = cities

                // Filter cities based on visited status
                self.visitedCities = cities.filter { $0.visited == true }
                print("Visited cities count: \(self.visitedCities.count)")
                self.bucketListCities = cities.filter { $0.visited == false }
                print("Bucket list cities count: \(self.bucketListCities.count)")

                // Cache cities for offline use
                CityCacheManager.shared.saveCities(cities, for: userId)

                if (wantCountries) {
                    await loadCountries(visitedCities)
                }

                // Load profile counts for cities and countries
                await loadProfileCounts()
            } catch {
                self.error = error
                print("Error loading user cities: \(error)")
                // Fallback to cache on network error
                loadFromCache(userId: userId)
            }
        } else {
            // Offline: load from cache
            loadFromCache(userId: userId)
        }

        isLoading = false
    }

    private func loadFromCache(userId: UUID) {
        let cachedCities = CityCacheManager.shared.loadCities(for: userId)

        if !cachedCities.isEmpty {
            self.allUserCities = cachedCities
            self.visitedCities = cachedCities.filter { $0.visited == true }
            self.bucketListCities = cachedCities.filter { $0.visited == false }
            self.isOfflineData = true
            print("Loaded \(cachedCities.count) cities from cache")

            // Also load countries from cache
            loadCountriesFromCache(userId: userId)
        }
    }
    
    func loadCountries(_ cities: [City]) async {
        guard let userId = _currentUserId else { return }
        error = nil

        let isOnline = NetworkMonitor.shared.isConnected

        if isOnline {
            do {
                // Use countryId to avoid name-matching issues; dedupe IDs first
                let countryIds = Array(Set(cities.map { $0.countryId }))
                let countriesData = try await databaseManager.getCountriesByIds(countryIds)

                // Cache countries for offline use
                CityCacheManager.shared.saveCountries(countriesData, for: userId)

                // Deduplicate names and continents
                let uniqueCountryNames = Array(Set(countriesData.map { $0.name })).sorted()
                let uniqueContinents = Array(Set(countriesData.map { $0.continent })).sorted()

                await MainActor.run {
                    self.visitedCountries = uniqueCountryNames
                    self.visitedContinents = uniqueContinents
                }
            } catch {
                Log.data.error("loadCountries failed: \(error)")
                await MainActor.run {
                    self.error = error
                }
                // Fallback to cache on error
                loadCountriesFromCache(userId: userId)
            }
        } else {
            // Offline: load from cache
            loadCountriesFromCache(userId: userId)
        }
    }

    private func loadCountriesFromCache(userId: UUID) {
        let cachedCountries = CityCacheManager.shared.loadCountries(for: userId)

        if !cachedCountries.isEmpty {
            let uniqueCountryNames = Array(Set(cachedCountries.map { $0.name })).sorted()
            let uniqueContinents = Array(Set(cachedCountries.map { $0.continent })).sorted()

            self.visitedCountries = uniqueCountryNames
            self.visitedContinents = uniqueContinents
            print("Loaded \(cachedCountries.count) countries from cache")
        }
    }

    func loadProfileCounts() async {
        guard let userId = _currentUserId else { return }

        do {
            let profile: Profile = try await supabase
                .from("profiles")
                .select("visited_cities_count, visited_countries_count")
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            self.visitedCitiesCount = profile.visitedCitiesCount ?? 0
            self.visitedCountriesCount = profile.visitedCountriesCount ?? 0
        } catch {
            print("Error loading profile counts: \(error)")
        }
    }
    
    func addCityToBucketList(cityId: Int) async {
        guard let userId = _currentUserId else { return }
        
        do {
            try await databaseManager.addCityToBucketList(
                userId: userId,
                cityId: cityId,
                notes: ""
            )
            await loadUserData() // Refresh data
        } catch {
            Log.data.error("addCityToBucketList failed for cityId \(cityId): \(error)")
            self.error = error
        }
    }

    func markCityAsVisited(cityId: Int, rating: Double? = nil, notes: String? = nil) async {
        guard let userId = _currentUserId else {
            print("🔴 markCityAsVisited failed: no current user ID")
            return
        }

        do {
            try await databaseManager.markCityAsVisited(
                userId: userId,
                cityId: cityId,
                rating: rating,
                notes: notes
            )
            print("🟢 ViewModel markCityAsVisited succeeded for cityId: \(cityId)")
            await loadUserData() // Refresh data
        } catch {
            print("🔴 ViewModel markCityAsVisited error for cityId \(cityId): \(error)")
            self.error = error
        }
    }
    
    func removeCityFromList(cityId: Int) async {
        guard let userId = _currentUserId else { return }
        
        do {
            try await databaseManager.removeUserCity(userId: userId, cityId: cityId)
            await loadUserData() // Refresh data
        } catch {
            Log.data.error("removeCityFromList failed for cityId \(cityId): \(error)")
            self.error = error
        }
    }
    
    // Helper method to get cities with relationship details
    private func getUserCitiesWithDetails(userId: UUID) async throws -> [City] {
        return try await databaseManager.getUserCities(userId: userId)
    }
    
    // MARK: - Rating Functions

    func updateCityRating(cityId: Int, rating: Double) async {
        await updateCityRatingWithoutRefresh(cityId: cityId, rating: rating)
        await loadUserData()
    }

    /// Updates city rating without refreshing data - use this for batch updates
    func updateCityRatingWithoutRefresh(cityId: Int, rating: Double) async {
        guard let userId = _currentUserId else { return }

        do {
            let ratingUpdate = CityRatingUpdate(
                cityId: cityId,
                rating: rating,
                userId: userId
            )
            try await databaseManager.updateCityRating(ratingUpdate)
        } catch {
            print("🔴 updateCityRatingWithoutRefresh error for cityId \(cityId): \(error)")
            self.error = error
        }
    }
    
    func updateCityNotes(cityId: Int, notes: String) async {
        guard let userId = _currentUserId else { return }
        
        do {
            try await databaseManager.updateUserCityNotes(
                userId: userId,
                cityId: cityId,
                notes: notes
            )
            await loadUserData() // Refresh data
        } catch {
            Log.data.error("updateCityNotes failed for cityId \(cityId): \(error)")
            self.error = error
        }
    }
    
    func getCityById(cityId: Int) async -> City? {
        guard let userId = _currentUserId else { return nil }

        // Check in-memory data first (already loaded by loadUserData)
        if let city = allUserCities.first(where: { $0.id == cityId }) {
            return city
        }

        let isOnline = NetworkMonitor.shared.isConnected

        if isOnline {
            do {
                return try await databaseManager.getCityWithUserData(cityId: cityId, userId: userId)
            } catch {
                Log.data.error("getCityById failed for cityId \(cityId): \(error)")
                self.error = error
                return getCityFromCache(cityId: cityId, userId: userId)
            }
        } else {
            return getCityFromCache(cityId: cityId, userId: userId)
        }
    }

    private func getCityFromCache(cityId: Int, userId: UUID) -> City? {
        let cachedCities = CityCacheManager.shared.loadCities(for: userId)
        return cachedCities.first { $0.id == cityId }
    }
}
