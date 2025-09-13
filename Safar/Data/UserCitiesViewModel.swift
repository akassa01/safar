import Foundation
import SwiftUI
import Supabase

@MainActor
class UserCitiesViewModel: ObservableObject {
    @Published var visitedCities: [City] = []
    @Published var bucketListCities: [City] = []
    @Published var allUserCities: [City] = []
    @Published var visitedCountries: [String] = []
    @Published var visitedContinents: [String] = []
    @Published var isLoading = false
    @Published var error: Error?
    
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
            self.setUserId(user.id)
            print("Current user id: \(user.id)")
        } catch {
            self.error = error
        }
    }

    func loadUserData() async {
        print("Checking user id")
        guard let userId = _currentUserId else { return }
        
        print("Getting user data")
        isLoading = true
        error = nil
        
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

            
            if (wantCountries) {
                await loadCountries(visitedCities)
            }
        } catch {
            self.error = error
            print("Error loading user cities: \(error)")
        }
        
        isLoading = false
    }
    
    func loadCountries(_ cities: [City]) async {
        error = nil
        do {
            // Use countryId to avoid name-matching issues; dedupe IDs first
            let countryIds = Array(Set(cities.map { $0.countryId }))
            let countriesData = try await databaseManager.getCountriesByIds(countryIds)

            // Deduplicate names and continents
            let uniqueCountryNames = Array(Set(countriesData.map { $0.name })).sorted()
            let uniqueContinents = Array(Set(countriesData.map { $0.continent })).sorted()

            await MainActor.run {
                self.visitedCountries = uniqueCountryNames
                self.visitedContinents = uniqueContinents
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
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
            self.error = error
        }
    }
    
    func markCityAsVisited(cityId: Int, rating: Double? = nil, notes: String? = nil) async {
        guard let userId = _currentUserId else { return }
        
        do {
            try await databaseManager.markCityAsVisited(
                userId: userId,
                cityId: cityId,
                rating: rating,
                notes: notes
            )
            await loadUserData() // Refresh data
        } catch {
            self.error = error
        }
    }
    
    func removeCityFromList(cityId: Int) async {
        guard let userId = _currentUserId else { return }
        
        do {
            try await databaseManager.removeUserCity(userId: userId, cityId: cityId)
            await loadUserData() // Refresh data
        } catch {
            self.error = error
        }
    }
    
    // Helper method to get cities with relationship details
    private func getUserCitiesWithDetails(userId: UUID) async throws -> [City] {
        return try await databaseManager.getUserCities(userId: userId)
    }
    
    // MARK: - Rating Functions
    
    func updateCityRating(cityId: Int, rating: Double) async {
        guard let userId = _currentUserId else { return }
        
        do {
            let ratingUpdate = CityRatingUpdate(
                cityId: cityId,
                rating: rating,
                userId: userId
            )
            try await databaseManager.updateCityRating(ratingUpdate)
            await loadUserData() // Refresh data
        } catch {
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
            self.error = error
        }
    }
    
    func getCityById(cityId: Int) async -> City? {
        guard let userId = _currentUserId else { return nil }
        
        do {
            return try await databaseManager.getCityWithUserData(cityId: cityId, userId: userId)
        } catch {
            self.error = error
            return nil
        }
    }
}
