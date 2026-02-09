//
//  DatabaseManager.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-04.
//

import Foundation
import Supabase

// MARK: - Models
struct City: Codable, Identifiable, Hashable {
    let id: Int
    let displayName: String
    let plainName: String
    let admin: String
    let country: String
    let countryId: Int64
    let population: Int
    let latitude: Double
    let longitude: Double

    // User-specific fields (from user_city join)
    let visited: Bool?
    let rating: Double?
    let notes: String?
    let userId: Int64?

    // Community rating fields
    let averageRating: Double?
    let ratingCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case plainName = "plain_name"
        case admin
        case country
        case countryId = "country_id"
        case population
        case latitude
        case longitude
        case visited
        case rating
        case notes
        case userId = "user_id"
        case averageRating = "average_rating"
        case ratingCount = "rating_count"
    }
}

// MARK: - Supabase Response Helpers
/// Shared response type for user_city queries with nested city data
struct UserCityResponse: Codable {
    let visited: Bool
    let rating: Double?
    let notes: String?
    let cities: CityData

    struct CityData: Codable {
        let id: Int
        let displayName: String
        let plainName: String
        let admin: String
        let country: String
        let countryId: Int64
        let population: Int
        let latitude: Double
        let longitude: Double
        let averageRating: Double?
        let ratingCount: Int?

        enum CodingKeys: String, CodingKey {
            case id
            case displayName = "display_name"
            case plainName = "plain_name"
            case admin
            case country
            case countryId = "country_id"
            case population
            case latitude
            case longitude
            case averageRating = "average_rating"
            case ratingCount = "rating_count"
        }
    }

    func toCity(userId: Int64? = nil) -> City {
        City(
            id: cities.id,
            displayName: cities.displayName,
            plainName: cities.plainName,
            admin: cities.admin,
            country: cities.country,
            countryId: cities.countryId,
            population: cities.population,
            latitude: cities.latitude,
            longitude: cities.longitude,
            visited: visited,
            rating: rating,
            notes: notes,
            userId: userId,
            averageRating: cities.averageRating,
            ratingCount: cities.ratingCount
        )
    }
}

/// Shared select query for user_city with nested city data
let userCitySelectQuery = """
    visited, rating, notes,
    cities:city_id (
        id, display_name, plain_name, admin, country,
        country_id, population, latitude, longitude,
        average_rating, rating_count
    )
"""

struct Country: Codable, Identifiable, Hashable {
    let id: Int64
    let name: String
    let countryCode: String
    let capital: String?
    let continent: String
    let population: Int64
    let averageRating: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case countryCode = "country_code"
        case capital
        case continent
        case population
        case averageRating = "average_rating"
    }
}

// MARK: - Rating Update Struct
struct CityRatingUpdate: Codable {
    let cityId: Int
    let rating: Double
    let userId: UUID
    
    enum CodingKeys: String, CodingKey {
        case cityId = "city_id"
        case rating
        case userId = "user_id"
    }
}

// MARK: - Database Errors
enum DatabaseError: LocalizedError {
    case userNotAuthenticated
    case cityNotFound
    case invalidData
    case networkError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated. Please log in again."
        case .cityNotFound:
            return "City not found in database."
        case .invalidData:
            return "Invalid data provided."
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

class DatabaseManager {
    static let shared = DatabaseManager()
    
    func getCurrentUser() async throws -> User {
        guard let user = supabase.auth.currentUser else {
            throw DatabaseError.userNotAuthenticated
        }
        return user
    }

    /// Get current user's ID string (non-throwing, returns nil if not authenticated)
    func getCurrentUserId() -> String? {
        return supabase.auth.currentUser?.id.uuidString
    }
    
    private func normalizeForSearch(_ text: String) -> String {
        return text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
    
    func searchCities(query: String) async throws -> [SearchResult] {
        // Use simple prefix search on plain_name
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DatabaseError.invalidData
        }

        let normalizedQuery = normalizeForSearch(query)

        do {
            let response: [City] = try await supabase
                .from("cities")
                .select("id, display_name, plain_name, admin, country, country_id, population, latitude, longitude")
                .ilike("plain_name", pattern: "\(normalizedQuery)%")
                .order("population", ascending: false)
                .limit(50)
                .execute()
                .value

            return response.map { city in
                let subtitle = [city.admin, city.country].filter { !$0.isEmpty }.joined(separator: ", ")
                return SearchResult(
                    title: city.displayName,
                    subtitle: subtitle,
                    latitude: city.latitude,
                    longitude: city.longitude,
                    population: city.population,
                    country: city.country,
                    admin: city.admin,
                    data_id: String(city.id)
                )
            }
        } catch {
            throw DatabaseError.networkError("Failed to search cities: \(error.localizedDescription)")
        }
    }

    func searchCitiesByDisplayName(query: String) async throws -> [SearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DatabaseError.invalidData
        }

        do {
            let response: [City] = try await supabase
                .from("cities")
                .select("id, display_name, plain_name, admin, country, country_id, population, latitude, longitude, created_at")
                .ilike("display_name", pattern: "%\(query)%")
                .limit(50)
                .execute()
                .value

            return response.map { city in
                let subtitle = [city.admin, city.country].filter { !$0.isEmpty }.joined(separator: ", ")
                return SearchResult(
                    title: city.displayName,
                    subtitle: subtitle,
                    latitude: Double(city.latitude),
                    longitude: Double(city.longitude),
                    population: city.population,
                    country: city.country,
                    admin: city.admin,
                    data_id: String(city.id)
                )
            }
        } catch {
            throw DatabaseError.networkError("Failed to search cities: \(error.localizedDescription)")
        }
    }

    func searchCountries(query: String) async throws -> [Country] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DatabaseError.invalidData
        }

        do {
            let response: [Country] = try await supabase
                .from("countries")
                .select("id, name, country_code, capital, continent, population, average_rating")
                .ilike("name", pattern: "%\(query)%")
                .order("population", ascending: false)
                .limit(50)
                .execute()
                .value

            return response
        } catch {
            throw DatabaseError.networkError("Failed to search countries: \(error.localizedDescription)")
        }
    }
    
    func getCountryAndContinent(forCountry country: String) async throws -> (country: String?, continent: String?) {
        guard !country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DatabaseError.invalidData
        }
        
        do {
            let response: [Country] = try await supabase
                .from("countries")
                .select("name, continent")
                .eq("name", value: country)
                .limit(1)
                .execute()
                .value
            
            if let countryData = response.first {
                return (countryData.name, countryData.continent)
            }
            
            return (nil, nil)
        } catch {
            throw DatabaseError.networkError("Failed to get country data: \(error.localizedDescription)")
        }
    }

    // Batch fetch countries by IDs to avoid repeated lookups and name-matching pitfalls
    func getCountriesByIds(_ ids: [Int64]) async throws -> [Country] {
        guard !ids.isEmpty else { return [] }
        do {
            let response: [Country] = try await supabase
                .from("countries")
                .select("id, name, country_code, capital, continent, population")
                .in("id", values: ids.map { Int($0) })
                .execute()
                .value
            return response
        } catch {
            throw DatabaseError.networkError("Failed to get countries by ids: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Additional helper methods for user-specific data
    
    func getUserCities(userId: UUID) async throws -> [City] {
        do {
            let response: [UserCityResponse] = try await supabase
                .from("user_city")
                .select(userCitySelectQuery)
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            return response.map { $0.toCity(userId: Int64(userId.hashValue)) }
        } catch {
            throw DatabaseError.networkError("Failed to get user cities: \(error.localizedDescription)")
        }
    }
    
    func addUserCity(userId: UUID, cityId: Int, visited: Bool = false, rating: Double? = nil, notes: String = "") async throws {
        struct UserCity: Codable {
            let userId: String
            let cityId: Int
            let visited: Bool
            let rating: Double?
            let notes: String
            
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case cityId = "city_id"
                case visited
                case rating
                case notes
            }
        }
        
        let userCity = UserCity(
            userId: userId.uuidString,
            cityId: cityId,
            visited: visited,
            rating: rating,
            notes: notes
        )
        
        do {
            try await supabase
                .from("user_city")
                .insert(userCity)
                .execute()
        } catch {
            throw DatabaseError.networkError("Failed to add user city: \(error.localizedDescription)")
        }
    }
    
    func updateUserCity(userId: UUID, cityId: Int, visited: Bool? = nil, rating: Double? = nil, notes: String? = nil) async throws {
        print("🟡 updateUserCity - cityId: \(cityId), visited: \(visited?.description ?? "nil"), rating: \(rating ?? -1), notes: '\(notes ?? "nil")'")

        do {
            // Update each field separately to ensure they're saved correctly
            if let visited = visited {
                print("🟡 Updating visited to \(visited)")
                try await supabase
                    .from("user_city")
                    .update(["visited": visited])
                    .eq("user_id", value: userId.uuidString)
                    .eq("city_id", value: cityId)
                    .execute()
            }
            if let rating = rating {
                print("🟡 Updating rating to \(rating)")
                try await supabase
                    .from("user_city")
                    .update(["rating": rating])
                    .eq("user_id", value: userId.uuidString)
                    .eq("city_id", value: cityId)
                    .execute()
            }
            if let notes = notes {
                print("🟡 Updating notes to '\(notes)'")
                try await supabase
                    .from("user_city")
                    .update(["notes": notes])
                    .eq("user_id", value: userId.uuidString)
                    .eq("city_id", value: cityId)
                    .execute()
            }
            print("🟡 updateUserCity completed successfully")
        } catch {
            print("🔴 updateUserCity error: \(error)")
            throw DatabaseError.networkError("Failed to update user city: \(error.localizedDescription)")
        }
    }
}


extension DatabaseManager {
    // This function is now replaced by the main getUserCities function above
    // Keeping for backward compatibility but it should use the main function
    func getUserCitiesWithUserData(userId: UUID) async throws -> [City] {
        return try await getUserCities(userId: userId)
    }
    
    func getVisitedCities(userId: UUID) async throws -> [City] {
        let allUserCities = try await getUserCitiesWithUserData(userId: userId)
        return allUserCities.filter { $0.visited == true }
    }
    
    func getBucketListCities(userId: UUID) async throws -> [City] {
        let allUserCities = try await getUserCitiesWithUserData(userId: userId)
        return allUserCities.filter { $0.visited == false }
    }
    
    // Updated methods to work with your schema
    func addCityToBucketList(userId: UUID, cityId: Int, notes: String = "") async throws {
        // Add city with visited = false (bucket list)
        try await addUserCity(userId: userId, cityId: cityId, visited: false, rating: nil, notes: notes)
    }
    
    func markCityAsVisited(userId: UUID, cityId: Int, rating: Double? = nil, notes: String? = nil) async throws {
        // If the user doesn't already have this city, insert it; otherwise update existing fields
        let hasCity = try await userHasCity(userId: userId, cityId: cityId)
        print("🟢 markCityAsVisited - cityId: \(cityId), hasCity: \(hasCity), rating: \(rating ?? -1), notes: '\(notes ?? "")'")

        if hasCity {
            print("🟢 Calling updateUserCity")
            try await updateUserCity(userId: userId, cityId: cityId, visited: true, rating: rating, notes: notes)
            print("🟢 updateUserCity completed")
        } else {
            print("🟢 Calling addUserCity")
            try await addUserCity(userId: userId, cityId: cityId, visited: true, rating: rating, notes: notes ?? "")
            print("🟢 addUserCity completed")
        }
    }
    
    func addVisitedCity(userId: UUID, cityId: Int, rating: Double? = nil, notes: String = "") async throws {
        // Add city as already visited
        try await addUserCity(userId: userId, cityId: cityId, visited: true, rating: rating, notes: notes)
    }
    
    func removeUserCity(userId: UUID, cityId: Int) async throws {
        do {
            try await supabase
                .from("user_city")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .eq("city_id", value: cityId)
                .execute()
        } catch {
            throw DatabaseError.networkError("Failed to remove user city: \(error.localizedDescription)")
        }
    }
    
    func updateUserCityNotes(userId: UUID, cityId: Int, notes: String) async throws {
        try await updateUserCity(userId: userId, cityId: cityId, notes: notes)
    }
    
    func updateUserCityRating(userId: UUID, cityId: Int, rating: Double?) async throws {
        try await updateUserCity(userId: userId, cityId: cityId, rating: rating)
    }
    
    func updateCityRating(_ ratingUpdate: CityRatingUpdate) async throws {
        try await updateUserCity(
            userId: ratingUpdate.userId,
            cityId: ratingUpdate.cityId,
            rating: ratingUpdate.rating
        )
    }
    
    // Get any city by ID (for CityDetailView)
    func getCityById(cityId: Int) async throws -> City? {
        do {
            // Define a simple city response structure for the cities table
            struct SimpleCityResponse: Codable {
                let id: Int
                let displayName: String
                let plainName: String
                let admin: String
                let country: String
                let countryId: Int64
                let population: Int
                let latitude: Double
                let longitude: Double
                let averageRating: Double?
                let ratingCount: Int?

                enum CodingKeys: String, CodingKey {
                    case id
                    case displayName = "display_name"
                    case plainName = "plain_name"
                    case admin
                    case country
                    case countryId = "country_id"
                    case population
                    case latitude
                    case longitude
                    case averageRating = "average_rating"
                    case ratingCount = "rating_count"
                }
            }

            let response: [SimpleCityResponse] = try await supabase
                .from("cities")
                .select("id, display_name, plain_name, admin, country, country_id, population, latitude, longitude, average_rating, rating_count")
                .eq("id", value: cityId)
                .limit(1)
                .execute()
                .value

            guard let cityData = response.first else { return nil }

            // Convert to City object with nil user data
            return City(
                id: cityData.id,
                displayName: cityData.displayName,
                plainName: cityData.plainName,
                admin: cityData.admin,
                country: cityData.country,
                countryId: cityData.countryId,
                population: cityData.population,
                latitude: cityData.latitude,
                longitude: cityData.longitude,
                visited: nil,
                rating: nil,
                notes: nil,
                userId: nil,
                averageRating: cityData.averageRating,
                ratingCount: cityData.ratingCount
            )
        } catch {
            throw DatabaseError.networkError("Failed to get city by ID: \(error.localizedDescription)")
        }
    }
    
    // Get city with user data if user has it
    func getCityWithUserData(cityId: Int, userId: UUID) async throws -> City? {
        do {
            // First try to get it from user cities
            let userCities = try await getUserCities(userId: userId)
            if let userCity = userCities.first(where: { $0.id == cityId }) {
                return userCity
            }
            
            // If not found in user cities, get basic city data
            return try await getCityById(cityId: cityId)
        } catch {
            throw DatabaseError.networkError("Failed to get city with user data: \(error.localizedDescription)")
        }
    }
    
    // Check if user already has this city (either visited or bucket list)
    func userHasCity(userId: UUID, cityId: Int) async throws -> Bool {
        struct ExistsResponse: Codable {
            let cityId: Int
            enum CodingKeys: String, CodingKey { case cityId = "city_id" }
        }
        do {
            let response: [ExistsResponse] = try await supabase
                .from("user_city")
                .select("city_id")
                .eq("user_id", value: userId.uuidString)
                .eq("city_id", value: cityId)
                .limit(1)
                .execute()
                .value
            return !response.isEmpty
        } catch {
            throw DatabaseError.networkError("Failed to check if user has city: \(error.localizedDescription)")
        }
    }
}

// MARK: - Places (user_place) CRUD
extension DatabaseManager {
    struct UserPlaceInsert: Codable {
        let name: String
        let latitude: Double
        let longitude: Double
        let category: String
        let cityId: Int
        let userId: String
        let liked: Bool?
        
        enum CodingKeys: String, CodingKey {
            case name
            case latitude
            case longitude
            case category
            case cityId = "city_id"
            case userId = "user_id"
            case liked
        }
    }

    /// Fetch all places created by a user for a given city
    func getUserPlaces(userId: UUID, cityId: Int) async throws -> [Place] {
        do {
            let response: [Place] = try await supabase
                .from("user_place")
                .select("id, created_at, name, latitude, longitude, category, city_id, user_id, liked")
                .eq("user_id", value: userId.uuidString)
                .eq("city_id", value: cityId)
                .execute()
                .value
            return response
        } catch {
            throw DatabaseError.networkError("Failed to get user places: \(error.localizedDescription)")
        }
    }

    /// Insert multiple places for a user and city
    func insertUserPlaces(userId: UUID, cityId: Int, places: [Place]) async throws {
        guard !places.isEmpty else { return }
        let payload: [UserPlaceInsert] = places.map { place in
            UserPlaceInsert(
                name: place.name,
                latitude: place.latitude,
                longitude: place.longitude,
                category: place.category.rawValue,
                cityId: cityId,
                userId: userId.uuidString,
                liked: place.liked
            )
        }
        do {
            try await supabase
                .from("user_place")
                .insert(payload)
                .execute()
        } catch {
            throw DatabaseError.networkError("Failed to insert user places: \(error.localizedDescription)")
        }
    }

    /// Update liked status for a place
    func updateUserPlaceLiked(placeId: Int, liked: Bool?) async throws {
        do {
            if let liked = liked {
                try await supabase
                    .from("user_place")
                    .update(["liked": liked])
                    .eq("id", value: placeId)
                    .execute()
            } else {
                // Encode JSON null by using an Optional value inside a dictionary
                let payload: [String: Bool?] = ["liked": nil]
                try await supabase
                    .from("user_place")
                    .update(payload)
                    .eq("id", value: placeId)
                    .execute()
            }
        } catch {
            throw DatabaseError.networkError("Failed to update place like: \(error.localizedDescription)")
        }
    }

    /// Delete a place by id (only the user's own place should be removed in UI)
    func deleteUserPlace(placeId: Int) async throws {
        do {
            try await supabase
                .from("user_place")
                .delete()
                .eq("id", value: placeId)
                .execute()
        } catch {
            throw DatabaseError.networkError("Failed to delete place: \(error.localizedDescription)")
        }
    }
}

// MARK: - People Search
extension DatabaseManager {
    /// Search profiles by username or full name
    func searchPeople(query: String) async throws -> [ProfileSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        do {
            let response: [ProfileSearchResult] = try await supabase
                .from("profiles")
                .select("id, username, full_name, avatar_url, visited_cities_count")
                .or("username.ilike.%\(trimmed)%,full_name.ilike.%\(trimmed)%")
                .limit(50)
                .execute()
                .value
            return response
        } catch {
            throw DatabaseError.networkError("Failed to search people: \(error.localizedDescription)")
        }
    }
}

// MARK: - Leaderboard Methods
extension DatabaseManager {
    private static let minimumRatingsForLeaderboard = 1

    /// Fetch top-rated cities for leaderboard
    func getTopRatedCities(limit: Int = 50, offset: Int = 0) async throws -> [CityLeaderboardEntry] {
        do {
            var entries: [CityLeaderboardEntry] = try await supabase
                .from("cities")
                .select("id, display_name, admin, country, average_rating, rating_count")
                .not("average_rating", operator: .is, value: "null")
                .gte("rating_count", value: Self.minimumRatingsForLeaderboard)
                .order("average_rating", ascending: false)
                .order("rating_count", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value

            // Add rank based on position
            for i in 0..<entries.count {
                entries[i].rank = offset + i + 1
            }
            return entries
        } catch {
            throw DatabaseError.networkError("Failed to fetch city leaderboard: \(error.localizedDescription)")
        }
    }

    /// Fetch top-rated cities filtered by continent
    func getTopRatedCitiesByContinent(continent: String, limit: Int = 20) async throws -> [CityLeaderboardEntry] {
        struct CountryName: Codable {
            let name: String
        }

        do {
            // First get country names for this continent
            let countries: [CountryName] = try await supabase
                .from("countries")
                .select("name")
                .eq("continent", value: continent)
                .execute()
                .value

            let countryNames = countries.map { $0.name }
            guard !countryNames.isEmpty else { return [] }

            var entries: [CityLeaderboardEntry] = try await supabase
                .from("cities")
                .select("id, display_name, admin, country, average_rating, rating_count")
                .in("country", values: countryNames)
                .not("average_rating", operator: .is, value: "null")
                .gte("rating_count", value: Self.minimumRatingsForLeaderboard)
                .order("average_rating", ascending: false)
                .limit(limit)
                .execute()
                .value

            for i in 0..<entries.count {
                entries[i].rank = i + 1
            }
            return entries
        } catch {
            throw DatabaseError.networkError("Failed to fetch continent leaderboard: \(error.localizedDescription)")
        }
    }

    /// Fetch top-rated countries
    func getTopRatedCountries(limit: Int = 50, offset: Int = 0, continent: String? = nil) async throws -> [CountryLeaderboardEntry] {
        do {
            var query = supabase
                .from("countries")
                .select("id, name, continent, average_rating")
                .not("average_rating", operator: .is, value: "null")

            if let continent = continent {
                query = query.eq("continent", value: continent)
            }

            var entries: [CountryLeaderboardEntry] = try await query
                .order("average_rating", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value

            for i in 0..<entries.count {
                entries[i].rank = offset + i + 1
            }
            return entries
        } catch {
            throw DatabaseError.networkError("Failed to fetch country leaderboard: \(error.localizedDescription)")
        }
    }

    /// Fetch users ranked by number of cities visited
    func getTopTravelersByCities(limit: Int = 50, offset: Int = 0) async throws -> [PeopleLeaderboardEntry] {
        do {
            var entries: [PeopleLeaderboardEntry] = try await supabase
                .from("profiles")
                .select("id, username, full_name, avatar_url, visited_cities_count, visited_countries_count")
                .gt("visited_cities_count", value: 0)
                .order("visited_cities_count", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value

            for i in 0..<entries.count {
                entries[i].rank = offset + i + 1
            }
            return entries
        } catch {
            throw DatabaseError.networkError("Failed to fetch people leaderboard by cities: \(error.localizedDescription)")
        }
    }

    /// Fetch users ranked by number of countries visited
    func getTopTravelersByCountries(limit: Int = 50, offset: Int = 0) async throws -> [PeopleLeaderboardEntry] {
        do {
            var entries: [PeopleLeaderboardEntry] = try await supabase
                .from("profiles")
                .select("id, username, full_name, avatar_url, visited_cities_count, visited_countries_count")
                .gt("visited_countries_count", value: 0)
                .order("visited_countries_count", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value

            for i in 0..<entries.count {
                entries[i].rank = offset + i + 1
            }
            return entries
        } catch {
            throw DatabaseError.networkError("Failed to fetch people leaderboard by countries: \(error.localizedDescription)")
        }
    }

    /// Fetch top-rated cities for a specific country (cities with 5+ ratings)
    func getTopCitiesForCountry(countryName: String, limit: Int = 50) async throws -> [CityLeaderboardEntry] {
        do {
            var entries: [CityLeaderboardEntry] = try await supabase
                .from("cities")
                .select("id, display_name, admin, country, average_rating, rating_count")
                .eq("country", value: countryName)
                .not("average_rating", operator: .is, value: "null")
                .gte("rating_count", value: Self.minimumRatingsForLeaderboard)
                .order("average_rating", ascending: false)
                .order("rating_count", ascending: false)
                .limit(limit)
                .execute()
                .value

            for i in 0..<entries.count {
                entries[i].rank = i + 1
            }
            return entries
        } catch {
            throw DatabaseError.networkError("Failed to fetch top cities for country: \(error.localizedDescription)")
        }
    }
}

// MARK: - Follow Operations
extension DatabaseManager {
    private struct FollowInsert: Codable {
        let followerId: String
        let followingId: String

        enum CodingKeys: String, CodingKey {
            case followerId = "follower_id"
            case followingId = "following_id"
        }
    }

    /// Follow a user
    func followUser(followingId: String) async throws {
        let currentUser = try await getCurrentUser()

        // Prevent self-following
        guard currentUser.id.uuidString != followingId else {
            throw DatabaseError.invalidData
        }

        let payload = FollowInsert(
            followerId: currentUser.id.uuidString,
            followingId: followingId
        )
        do {
            try await supabase
                .from("follows")
                .insert(payload)
                .execute()
        } catch {
            throw DatabaseError.networkError("Failed to follow user: \(error.localizedDescription)")
        }
    }

    /// Unfollow a user
    func unfollowUser(followingId: String) async throws {
        let currentUser = try await getCurrentUser()
        do {
            try await supabase
                .from("follows")
                .delete()
                .eq("follower_id", value: currentUser.id.uuidString)
                .eq("following_id", value: followingId)
                .execute()
        } catch {
            throw DatabaseError.networkError("Failed to unfollow user: \(error.localizedDescription)")
        }
    }

    /// Check if current user follows another user
    func isFollowing(userId: String) async throws -> Bool {
        let currentUser = try await getCurrentUser()
        struct FollowCheck: Codable {
            let id: Int64
        }
        do {
            let response: [FollowCheck] = try await supabase
                .from("follows")
                .select("id")
                .eq("follower_id", value: currentUser.id.uuidString)
                .eq("following_id", value: userId)
                .limit(1)
                .execute()
                .value
            return !response.isEmpty
        } catch {
            throw DatabaseError.networkError("Failed to check follow status: \(error.localizedDescription)")
        }
    }

    /// Get followers of a user
    func getFollowers(userId: String) async throws -> [FollowUser] {
        do {
            // Step 1: Get follower IDs
            struct FollowRecord: Codable {
                let followerId: String
                enum CodingKeys: String, CodingKey {
                    case followerId = "follower_id"
                }
            }

            let followRecords: [FollowRecord] = try await supabase
                .from("follows")
                .select("follower_id")
                .eq("following_id", value: userId)
                .execute()
                .value

            guard !followRecords.isEmpty else { return [] }

            // Step 2: Get profiles for those IDs
            let followerIds = followRecords.map { $0.followerId }
            let profiles: [FollowUser] = try await supabase
                .from("profiles")
                .select("id, username, full_name, avatar_url, visited_cities_count")
                .in("id", values: followerIds)
                .execute()
                .value

            return profiles
        } catch {
            throw DatabaseError.networkError("Failed to get followers: \(error.localizedDescription)")
        }
    }

    /// Get users that a user is following
    func getFollowing(userId: String) async throws -> [FollowUser] {
        do {
            // Step 1: Get following IDs
            struct FollowRecord: Codable {
                let followingId: String
                enum CodingKeys: String, CodingKey {
                    case followingId = "following_id"
                }
            }

            let followRecords: [FollowRecord] = try await supabase
                .from("follows")
                .select("following_id")
                .eq("follower_id", value: userId)
                .execute()
                .value

            guard !followRecords.isEmpty else { return [] }

            // Step 2: Get profiles for those IDs
            let followingIds = followRecords.map { $0.followingId }
            let profiles: [FollowUser] = try await supabase
                .from("profiles")
                .select("id, username, full_name, avatar_url, visited_cities_count")
                .in("id", values: followingIds)
                .execute()
                .value

            return profiles
        } catch {
            throw DatabaseError.networkError("Failed to get following: \(error.localizedDescription)")
        }
    }

    /// Get follower and following counts for a user
    func getFollowCounts(userId: String) async throws -> (followers: Int, following: Int) {
        do {
            // Get follower count (people who follow this user)
            let followersResponse = try await supabase
                .from("follows")
                .select("*", head: true, count: .exact)
                .eq("following_id", value: userId)
                .execute()

            // Get following count (people this user follows)
            let followingResponse = try await supabase
                .from("follows")
                .select("*", head: true, count: .exact)
                .eq("follower_id", value: userId)
                .execute()

            return (followers: followersResponse.count ?? 0, following: followingResponse.count ?? 0)
        } catch {
            // If counts fail, return 0s - we can still show the profile
            return (followers: 0, following: 0)
        }
    }
}

// MARK: - User Profile Operations
extension DatabaseManager {
    /// Get a user's full profile
    func getUserProfile(userId: String) async throws -> UserProfile {
        do {
            let response: UserProfile = try await supabase
                .from("profiles")
                .select("id, username, full_name, avatar_url, bio, visited_cities_count, visited_countries_count")
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            return response
        } catch {
            throw DatabaseError.networkError("Failed to get user profile: \(error.localizedDescription)")
        }
    }

    /// Get visited cities for any user (for viewing other profiles)
    func getVisitedCitiesForUser(userId: String) async throws -> [City] {
        do {
            let response: [UserCityResponse] = try await supabase
                .from("user_city")
                .select(userCitySelectQuery)
                .eq("user_id", value: userId)
                .eq("visited", value: true)
                .execute()
                .value

            return response.map { $0.toCity() }
        } catch {
            throw DatabaseError.networkError("Failed to get user's visited cities: \(error.localizedDescription)")
        }
    }

    /// Get bucket list cities for any user (for viewing other profiles)
    func getBucketListCitiesForUser(userId: String) async throws -> [City] {
        do {
            let response: [UserCityResponse] = try await supabase
                .from("user_city")
                .select(userCitySelectQuery)
                .eq("user_id", value: userId)
                .eq("visited", value: false)
                .execute()
                .value

            return response.map { $0.toCity() }
        } catch {
            throw DatabaseError.networkError("Failed to get user's bucket list cities: \(error.localizedDescription)")
        }
    }

    /// Get continents count for a user based on their visited cities
    func getContinentsCountForUser(userId: String) async throws -> Int {
        do {
            let cities = try await getVisitedCitiesForUser(userId: userId)
            let countryIds = Array(Set(cities.map { $0.countryId }))
            guard !countryIds.isEmpty else { return 0 }

            let countries = try await getCountriesByIds(countryIds)
            let continents = Set(countries.map { $0.continent })
            return continents.count
        } catch {
            return 0
        }
    }
}

// MARK: - Feed Operations
extension DatabaseManager {

    /// Get IDs of users the current user follows
    private func getFollowingIds(userId: String) async throws -> [String] {
        struct FollowRecord: Codable {
            let followingId: String
            enum CodingKeys: String, CodingKey {
                case followingId = "following_id"
            }
        }

        let records: [FollowRecord] = try await supabase
            .from("follows")
            .select("following_id")
            .eq("follower_id", value: userId)
            .execute()
            .value

        return records.map { $0.followingId }
    }

    /// Get profiles by IDs (batch fetch)
    private func getProfilesByIds(_ ids: [String]) async throws -> [ProfileSearchResult] {
        guard !ids.isEmpty else { return [] }

        return try await supabase
            .from("profiles")
            .select("id, username, full_name, avatar_url, visited_cities_count")
            .in("id", values: ids)
            .execute()
            .value
    }

    /// Get like counts for multiple posts
    private func getLikeCounts(for postIds: [Int64]) async throws -> [Int64: Int] {
        guard !postIds.isEmpty else { return [:] }

        struct LikeRecord: Codable {
            let userCityId: Int64
            enum CodingKeys: String, CodingKey {
                case userCityId = "user_city_id"
            }
        }

        let likes: [LikeRecord] = try await supabase
            .from("post_likes")
            .select("user_city_id")
            .in("user_city_id", values: postIds.map { Int($0) })
            .execute()
            .value

        // Count likes per post
        var counts: [Int64: Int] = [:]
        for like in likes {
            counts[like.userCityId, default: 0] += 1
        }
        return counts
    }

    /// Check which posts the current user has liked
    private func getUserLikeStatus(for postIds: [Int64], userId: String) async throws -> Set<Int64> {
        guard !postIds.isEmpty else { return [] }

        struct UserLike: Codable {
            let userCityId: Int64
            enum CodingKeys: String, CodingKey {
                case userCityId = "user_city_id"
            }
        }

        let likes: [UserLike] = try await supabase
            .from("post_likes")
            .select("user_city_id")
            .eq("user_id", value: userId)
            .in("user_city_id", values: postIds.map { Int($0) })
            .execute()
            .value

        return Set(likes.map { $0.userCityId })
    }

    /// Get comment counts for multiple posts
    private func getCommentCounts(for postIds: [Int64]) async throws -> [Int64: Int] {
        guard !postIds.isEmpty else { return [:] }

        struct CommentRecord: Codable {
            let userCityId: Int64
            enum CodingKeys: String, CodingKey {
                case userCityId = "user_city_id"
            }
        }

        let comments: [CommentRecord] = try await supabase
            .from("post_comments")
            .select("user_city_id")
            .in("user_city_id", values: postIds.map { Int($0) })
            .execute()
            .value

        var counts: [Int64: Int] = [:]
        for comment in comments {
            counts[comment.userCityId, default: 0] += 1
        }
        return counts
    }

    /// Get social data (like count, comment count, like status) for a single post
    func getPostSocialData(userCityId: Int64) async throws -> (likeCount: Int, commentCount: Int, isLiked: Bool) {
        let currentUserId = getCurrentUserId() ?? ""
        let likeCounts = try await getLikeCounts(for: [userCityId])
        let commentCounts = try await getCommentCounts(for: [userCityId])
        let userLikes = try await getUserLikeStatus(for: [userCityId], userId: currentUserId)
        return (
            likeCount: likeCounts[userCityId] ?? 0,
            commentCount: commentCounts[userCityId] ?? 0,
            isLiked: userLikes.contains(userCityId)
        )
    }

    /// Get feed posts from followed users
    func getFeedPosts(limit: Int = 20, offset: Int = 0) async throws -> [FeedPost] {
        let currentUser = try await getCurrentUser()
        let currentUserId = currentUser.id.uuidString

        // Step 1: Get followed user IDs
        let followedIds = try await getFollowingIds(userId: currentUserId)
        guard !followedIds.isEmpty else { return [] }

        // Step 2: Fetch user_city entries with city data
        let response: [FeedPost.FeedPostResponse] = try await supabase
            .from("user_city")
            .select("""
                id, user_id, visited, rating, notes, visited_at,
                city_id (id, display_name, admin, country, latitude, longitude)
            """)
            .in("user_id", values: followedIds)
            .eq("visited", value: true)
            .order("visited_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        guard !response.isEmpty else { return [] }

        // Step 3: Get unique user IDs and fetch profiles
        let userIds = Array(Set(response.map { $0.userId }))
        let profiles = try await getProfilesByIds(userIds)
        let profileMap = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })

        // Step 4: Get like counts and current user like status
        let postIds = response.map { $0.id }
        let likeCounts = try await getLikeCounts(for: postIds)
        let userLikes = try await getUserLikeStatus(for: postIds, userId: currentUserId)

        // Step 5: Get comment counts
        let commentCounts = try await getCommentCounts(for: postIds)

        // Step 6: Fetch places for each post (batch by city)
        var placesMap: [Int64: [Place]] = [:]
        for item in response {
            if let userId = UUID(uuidString: item.userId) {
                let places = try await getUserPlaces(userId: userId, cityId: item.cities.id)
                placesMap[item.id] = places
            }
        }

        // Step 7: Assemble FeedPost objects
        return response.map { item in
            let profile = profileMap[item.userId]
            var post = FeedPost(from: item)
            post.username = profile?.username
            post.fullName = profile?.fullName
            post.avatarURL = profile?.avatarURL
            post.likeCount = likeCounts[item.id] ?? 0
            post.commentCount = commentCounts[item.id] ?? 0
            post.isLikedByCurrentUser = userLikes.contains(item.id)
            post.places = placesMap[item.id] ?? []
            return post
        }
    }

    /// Get feed posts for a specific user
    func getUserFeedPosts(userId: String, limit: Int = 20, offset: Int = 0) async throws -> [FeedPost] {
        let currentUserId = getCurrentUserId() ?? ""

        let response: [FeedPost.FeedPostResponse] = try await supabase
            .from("user_city")
            .select("""
                id, user_id, visited, rating, notes, visited_at,
                city_id (id, display_name, admin, country, latitude, longitude)
            """)
            .eq("user_id", value: userId)
            .eq("visited", value: true)
            .order("visited_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        guard !response.isEmpty else { return [] }

        let profiles = try await getProfilesByIds([userId])
        let profileMap = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })

        let postIds = response.map { $0.id }
        let likeCounts = try await getLikeCounts(for: postIds)
        let userLikes = try await getUserLikeStatus(for: postIds, userId: currentUserId)
        let commentCounts = try await getCommentCounts(for: postIds)

        var placesMap: [Int64: [Place]] = [:]
        for item in response {
            if let uid = UUID(uuidString: item.userId) {
                let places = try await getUserPlaces(userId: uid, cityId: item.cities.id)
                placesMap[item.id] = places
            }
        }

        return response.map { item in
            let profile = profileMap[item.userId]
            var post = FeedPost(from: item)
            post.username = profile?.username
            post.fullName = profile?.fullName
            post.avatarURL = profile?.avatarURL
            post.likeCount = likeCounts[item.id] ?? 0
            post.commentCount = commentCounts[item.id] ?? 0
            post.isLikedByCurrentUser = userLikes.contains(item.id)
            post.places = placesMap[item.id] ?? []
            return post
        }
    }

    // MARK: - Like Operations

    /// Like a post
    func likePost(userCityId: Int64) async throws {
        let currentUser = try await getCurrentUser()

        struct LikeInsert: Codable {
            let userCityId: Int64
            let userId: String

            enum CodingKeys: String, CodingKey {
                case userCityId = "user_city_id"
                case userId = "user_id"
            }
        }

        do {
            try await supabase
                .from("post_likes")
                .insert(LikeInsert(userCityId: userCityId, userId: currentUser.id.uuidString))
                .execute()
        } catch {
            throw DatabaseError.networkError("Failed to like post: \(error.localizedDescription)")
        }
    }

    /// Unlike a post
    func unlikePost(userCityId: Int64) async throws {
        let currentUser = try await getCurrentUser()

        do {
            try await supabase
                .from("post_likes")
                .delete()
                .eq("user_city_id", value: Int(userCityId))
                .eq("user_id", value: currentUser.id.uuidString)
                .execute()
        } catch {
            throw DatabaseError.networkError("Failed to unlike post: \(error.localizedDescription)")
        }
    }

    /// Get all likes for a post (with user profiles)
    func getPostLikes(userCityId: Int64) async throws -> [PostLike] {
        struct LikeResponse: Codable {
            let id: Int64
            let userCityId: Int64
            let userId: String
            let createdAt: Date

            enum CodingKeys: String, CodingKey {
                case id
                case userCityId = "user_city_id"
                case userId = "user_id"
                case createdAt = "created_at"
            }
        }

        let likes: [LikeResponse] = try await supabase
            .from("post_likes")
            .select("id, user_city_id, user_id, created_at")
            .eq("user_city_id", value: Int(userCityId))
            .order("created_at", ascending: false)
            .execute()
            .value

        guard !likes.isEmpty else { return [] }

        // Fetch profiles for likers
        let userIds = likes.map { $0.userId }
        let profiles = try await getProfilesByIds(userIds)
        let profileMap = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })

        return likes.map { like in
            var postLike = PostLike(
                id: like.id,
                userCityId: like.userCityId,
                userId: like.userId,
                createdAt: like.createdAt
            )
            postLike.username = profileMap[like.userId]?.username
            postLike.fullName = profileMap[like.userId]?.fullName
            postLike.avatarURL = profileMap[like.userId]?.avatarURL
            return postLike
        }
    }

    // MARK: - Comment Operations

    /// Get all comments for a post
    func getPostComments(userCityId: Int64) async throws -> [PostComment] {
        struct CommentResponse: Codable {
            let id: Int64
            let userCityId: Int64
            let userId: String
            let content: String
            let createdAt: Date

            enum CodingKeys: String, CodingKey {
                case id
                case userCityId = "user_city_id"
                case userId = "user_id"
                case content
                case createdAt = "created_at"
            }
        }

        let comments: [CommentResponse] = try await supabase
            .from("post_comments")
            .select("id, user_city_id, user_id, content, created_at")
            .eq("user_city_id", value: Int(userCityId))
            .order("created_at", ascending: true)
            .execute()
            .value

        guard !comments.isEmpty else { return [] }

        // Fetch profiles for commenters
        let userIds = Array(Set(comments.map { $0.userId }))
        let profiles = try await getProfilesByIds(userIds)
        let profileMap = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })

        return comments.map { comment in
            var postComment = PostComment(
                id: comment.id,
                userCityId: comment.userCityId,
                userId: comment.userId,
                content: comment.content,
                createdAt: comment.createdAt
            )
            postComment.username = profileMap[comment.userId]?.username
            postComment.fullName = profileMap[comment.userId]?.fullName
            postComment.avatarURL = profileMap[comment.userId]?.avatarURL
            return postComment
        }
    }

    /// Add a comment to a post
    func addComment(userCityId: Int64, content: String) async throws -> PostComment {
        let currentUser = try await getCurrentUser()

        struct CommentInsert: Codable {
            let userCityId: Int64
            let userId: String
            let content: String

            enum CodingKeys: String, CodingKey {
                case userCityId = "user_city_id"
                case userId = "user_id"
                case content
            }
        }

        struct CommentResponse: Codable {
            let id: Int64
            let userCityId: Int64
            let userId: String
            let content: String
            let createdAt: Date

            enum CodingKeys: String, CodingKey {
                case id
                case userCityId = "user_city_id"
                case userId = "user_id"
                case content
                case createdAt = "created_at"
            }
        }

        let response: CommentResponse = try await supabase
            .from("post_comments")
            .insert(CommentInsert(userCityId: userCityId, userId: currentUser.id.uuidString, content: content))
            .select()
            .single()
            .execute()
            .value

        // Get current user's profile for the returned comment
        let profile = try await getUserProfile(userId: currentUser.id.uuidString)

        var comment = PostComment(
            id: response.id,
            userCityId: response.userCityId,
            userId: response.userId,
            content: response.content,
            createdAt: response.createdAt
        )
        comment.username = profile.username
        comment.fullName = profile.fullName
        comment.avatarURL = profile.avatarURL

        return comment
    }

    /// Delete a comment (only own comments)
    func deleteComment(commentId: Int64) async throws {
        let currentUser = try await getCurrentUser()

        do {
            try await supabase
                .from("post_comments")
                .delete()
                .eq("id", value: Int(commentId))
                .eq("user_id", value: currentUser.id.uuidString)
                .execute()
        } catch {
            throw DatabaseError.networkError("Failed to delete comment: \(error.localizedDescription)")
        }
    }
}

// MARK: - City Overview Operations
extension DatabaseManager {
    /// Get friends (people current user follows) who have visited a specific city
    func getFriendsWhoVisitedCity(cityId: Int, userId: String) async throws -> [FriendCityVisit] {
        // Step 1: Get IDs of users the current user follows
        struct FollowRecord: Codable {
            let followingId: String
            enum CodingKeys: String, CodingKey {
                case followingId = "following_id"
            }
        }

        let followRecords: [FollowRecord] = try await supabase
            .from("follows")
            .select("following_id")
            .eq("follower_id", value: userId)
            .execute()
            .value

        guard !followRecords.isEmpty else { return [] }
        let followingIds = followRecords.map { $0.followingId }

        // Step 2: Get user_city entries for those users who visited this city
        struct UserCityRecord: Codable {
            let id: Int64
            let userId: String
            let rating: Double?
            let notes: String?
            let visitedAt: Date?

            enum CodingKeys: String, CodingKey {
                case id
                case userId = "user_id"
                case rating
                case notes
                case visitedAt = "visited_at"
            }
        }

        let userCityRecords: [UserCityRecord] = try await supabase
            .from("user_city")
            .select("id, user_id, rating, notes, visited_at")
            .eq("city_id", value: cityId)
            .eq("visited", value: true)
            .in("user_id", values: followingIds)
            .order("visited_at", ascending: false)
            .execute()
            .value

        guard !userCityRecords.isEmpty else { return [] }

        // Step 3: Get profiles for those users
        let userIds = userCityRecords.map { $0.userId }
        let profiles: [ProfileSearchResult] = try await supabase
            .from("profiles")
            .select("id, username, full_name, avatar_url, visited_cities_count")
            .in("id", values: userIds)
            .execute()
            .value

        let profileMap = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })

        // Step 4: Combine into FriendCityVisit objects
        return userCityRecords.map { record in
            let profile = profileMap[record.userId]
            return FriendCityVisit(
                id: String(record.id),
                userId: record.userId,
                username: profile?.username,
                fullName: profile?.fullName,
                avatarURL: profile?.avatarURL,
                rating: record.rating,
                visitedAt: record.visitedAt,
                notes: record.notes
            )
        }
    }

}
