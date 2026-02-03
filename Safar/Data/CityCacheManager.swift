//
//  CityCacheManager.swift
//  safar
//
//  Manages SwiftData cache for offline viewing of cities, places, and countries
//

import Foundation
import SwiftData

@MainActor
class CityCacheManager {
    static let shared = CityCacheManager()

    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?

    private let lastSyncKey = "CityCacheManager.lastSyncDate"

    private init() {
        do {
            let schema = Schema([CachedCity.self, CachedPlace.self, CachedCountry.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = modelContainer?.mainContext
        } catch {
            print("Failed to initialize SwiftData container: \(error)")
        }
    }

    // MARK: - Last Sync Date

    var lastSyncDate: Date? {
        get { UserDefaults.standard.object(forKey: lastSyncKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastSyncKey) }
    }

    // MARK: - City Operations

    func saveCities(_ cities: [City], for userId: UUID) {
        guard let context = modelContext else { return }

        let userIdString = userId.uuidString

        do {
            // Get existing cached cities for this user
            let descriptor = FetchDescriptor<CachedCity>(
                predicate: #Predicate { $0.userId == userIdString }
            )
            let existingCities = try context.fetch(descriptor)
            let existingById = Dictionary(uniqueKeysWithValues: existingCities.map { ($0.id, $0) })

            // Track which IDs we've seen from the server
            var serverCityIds = Set<Int>()

            for city in cities {
                serverCityIds.insert(city.id)

                if let existing = existingById[city.id] {
                    // Update existing record
                    existing.displayName = city.displayName
                    existing.plainName = city.plainName
                    existing.admin = city.admin
                    existing.country = city.country
                    existing.countryId = city.countryId
                    existing.population = city.population
                    existing.latitude = city.latitude
                    existing.longitude = city.longitude
                    existing.visited = city.visited ?? false
                    existing.rating = city.rating
                    existing.notes = city.notes
                    existing.averageRating = city.averageRating
                    existing.ratingCount = city.ratingCount
                    existing.lastUpdated = Date()
                } else {
                    // Insert new record
                    let cached = CachedCity(from: city, userId: userId)
                    context.insert(cached)
                }
            }

            // Remove cities that no longer exist on the server
            for existing in existingCities {
                if !serverCityIds.contains(existing.id) {
                    context.delete(existing)
                    // Also delete associated places
                    deletePlaces(for: existing.id, userId: userId)
                }
            }

            try context.save()
            lastSyncDate = Date()
            print("Cached \(cities.count) cities for offline use")
        } catch {
            print("Failed to save cities to cache: \(error)")
        }
    }

    func loadCities(for userId: UUID) -> [City] {
        guard let context = modelContext else { return [] }

        let userIdString = userId.uuidString

        do {
            let descriptor = FetchDescriptor<CachedCity>(
                predicate: #Predicate { $0.userId == userIdString }
            )
            let cached = try context.fetch(descriptor)
            return cached.map { $0.toCity() }
        } catch {
            print("Failed to load cities from cache: \(error)")
            return []
        }
    }

    func clearCityCache(for userId: UUID) {
        guard let context = modelContext else { return }

        let userIdString = userId.uuidString

        do {
            let descriptor = FetchDescriptor<CachedCity>(
                predicate: #Predicate { $0.userId == userIdString }
            )
            let existing = try context.fetch(descriptor)
            for city in existing {
                context.delete(city)
            }
            try context.save()
            print("Cleared city cache for user")
        } catch {
            print("Failed to clear city cache: \(error)")
        }
    }

    // MARK: - Place Operations

    func savePlaces(_ places: [Place], for cityId: Int, userId: UUID) {
        guard let context = modelContext else { return }

        let userIdString = userId.uuidString

        do {
            // Delete existing places for this city and user
            let descriptor = FetchDescriptor<CachedPlace>(
                predicate: #Predicate { $0.cityId == cityId && $0.userId == userIdString }
            )
            let existing = try context.fetch(descriptor)
            for place in existing {
                context.delete(place)
            }

            // Insert new places
            for place in places {
                let cached = CachedPlace(from: place, userId: userId)
                context.insert(cached)
            }

            try context.save()
            print("Cached \(places.count) places for city \(cityId)")
        } catch {
            print("Failed to save places to cache: \(error)")
        }
    }

    func loadPlaces(for cityId: Int, userId: UUID) -> [Place] {
        guard let context = modelContext else { return [] }

        let userIdString = userId.uuidString

        do {
            let descriptor = FetchDescriptor<CachedPlace>(
                predicate: #Predicate { $0.cityId == cityId && $0.userId == userIdString }
            )
            let cached = try context.fetch(descriptor)
            return cached.map { $0.toPlace() }
        } catch {
            print("Failed to load places from cache: \(error)")
            return []
        }
    }

    func deletePlaces(for cityId: Int, userId: UUID) {
        guard let context = modelContext else { return }

        let userIdString = userId.uuidString

        do {
            let descriptor = FetchDescriptor<CachedPlace>(
                predicate: #Predicate { $0.cityId == cityId && $0.userId == userIdString }
            )
            let existing = try context.fetch(descriptor)
            for place in existing {
                context.delete(place)
            }
            try context.save()
        } catch {
            print("Failed to delete places from cache: \(error)")
        }
    }

    func clearPlaceCache(for userId: UUID) {
        guard let context = modelContext else { return }

        let userIdString = userId.uuidString

        do {
            let descriptor = FetchDescriptor<CachedPlace>(
                predicate: #Predicate { $0.userId == userIdString }
            )
            let existing = try context.fetch(descriptor)
            for place in existing {
                context.delete(place)
            }
            try context.save()
            print("Cleared place cache for user")
        } catch {
            print("Failed to clear place cache: \(error)")
        }
    }

    // MARK: - Country Operations

    func saveCountries(_ countries: [Country], for userId: UUID) {
        guard let context = modelContext else { return }

        let userIdString = userId.uuidString

        do {
            // Get existing cached countries for this user
            let descriptor = FetchDescriptor<CachedCountry>(
                predicate: #Predicate { $0.userId == userIdString }
            )
            let existingCountries = try context.fetch(descriptor)
            let existingById = Dictionary(uniqueKeysWithValues: existingCountries.map { ($0.id, $0) })

            for country in countries {
                if let existing = existingById[country.id] {
                    // Update existing record
                    existing.name = country.name
                    existing.countryCode = country.countryCode
                    existing.capital = country.capital
                    existing.continent = country.continent
                    existing.population = country.population
                    existing.averageRating = country.averageRating
                    existing.lastUpdated = Date()
                } else {
                    // Insert new record
                    let cached = CachedCountry(from: country, userId: userId)
                    context.insert(cached)
                }
            }

            try context.save()
            print("Cached \(countries.count) countries for offline use")
        } catch {
            print("Failed to save countries to cache: \(error)")
        }
    }

    func loadCountries(for userId: UUID) -> [Country] {
        guard let context = modelContext else { return [] }

        let userIdString = userId.uuidString

        do {
            let descriptor = FetchDescriptor<CachedCountry>(
                predicate: #Predicate { $0.userId == userIdString }
            )
            let cached = try context.fetch(descriptor)
            return cached.map { $0.toCountry() }
        } catch {
            print("Failed to load countries from cache: \(error)")
            return []
        }
    }

    func clearCountryCache(for userId: UUID) {
        guard let context = modelContext else { return }

        let userIdString = userId.uuidString

        do {
            let descriptor = FetchDescriptor<CachedCountry>(
                predicate: #Predicate { $0.userId == userIdString }
            )
            let existing = try context.fetch(descriptor)
            for country in existing {
                context.delete(country)
            }
            try context.save()
            print("Cleared country cache for user")
        } catch {
            print("Failed to clear country cache: \(error)")
        }
    }

    // MARK: - Clear All Cache

    func clearCache(for userId: UUID) {
        clearCityCache(for: userId)
        clearPlaceCache(for: userId)
        clearCountryCache(for: userId)
        lastSyncDate = nil
    }
}
