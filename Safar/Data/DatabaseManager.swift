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
    
    let visited: Bool?
    let rating: Double?
    let notes: String?
    let userId: Int64?
    
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
    }
}

struct Country: Codable {
    let id: Int64
    let name: String
    let countryCode: String
    let capital: String?
    let continent: String
    let population: Int64
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case countryCode = "country_code"
        case capital
        case continent
        case population
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
    
    private func normalizeForSearch(_ text: String) -> String {
        return text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
    
    func searchCities(query: String) async throws -> [SearchResult] {
        // Use fuzzy search for better matching
        return try await searchCitiesFuzzy(query: query, similarityThreshold: 0.3)
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

    func searchCitiesFuzzy(query: String, similarityThreshold: Double = 0.3) async throws -> [SearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DatabaseError.invalidData
        }

        struct FuzzyParams: Encodable {
            let search_query: String
            let similarity_threshold: Double
            let result_limit: Int
        }

        struct FuzzyResult: Codable {
            let id: Int
            let displayName: String
            let plainName: String
            let admin: String
            let country: String
            let countryId: Int
            let population: Int
            let latitude: Double
            let longitude: Double
            let similarityScore: Double

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
                case similarityScore = "similarity_score"
            }
        }

        let params = FuzzyParams(
            search_query: query,
            similarity_threshold: similarityThreshold,
            result_limit: 50
        )

        let response: [FuzzyResult] = try await supabase
            .rpc("search_cities_fuzzy", params: params)
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
    }

    func searchCountries(query: String) async throws -> [Country] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DatabaseError.invalidData
        }
        
        do {
            let response: [Country] = try await supabase
                .from("countries")
                .select("name")
                .ilike("name", pattern: "%\(query)%")
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
               // Define the response structure for the nested query
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
                       }
                   }
               }
               
               let response: [UserCityResponse] = try await supabase
                   .from("user_city")
                   .select("""
                       visited, rating, notes,
                       cities:city_id (
                           id, display_name, plain_name, admin, country, 
                           country_id, population, latitude, longitude
                       )
                   """)
                   .eq("user_id", value: userId.uuidString)
                   .execute()
                   .value
               
               // Convert the nested response to City objects
               return response.map { userCity in
                   City(
                       id: userCity.cities.id,
                       displayName: userCity.cities.displayName,
                       plainName: userCity.cities.plainName,
                       admin: userCity.cities.admin,
                       country: userCity.cities.country,
                       countryId: userCity.cities.countryId,
                       population: userCity.cities.population,
                       latitude: userCity.cities.latitude,
                       longitude: userCity.cities.longitude,
                       visited: userCity.visited,
                       rating: userCity.rating,
                       notes: userCity.notes,
                       userId: Int64(userId.hashValue) // Use a consistent userId representation
                   )
               }
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
                }
            }
            
            let response: [SimpleCityResponse] = try await supabase
                .from("cities")
                .select("id, display_name, plain_name, admin, country, country_id, population, latitude, longitude, created_at")
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
                userId: nil
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
                .select("id, username, full_name, avatar_url")
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
