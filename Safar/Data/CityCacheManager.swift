//
//  CityCacheManager.swift
//  safar
//
//  Manages SwiftData cache for offline city viewing
//

import Foundation
import SwiftData

@MainActor
class CityCacheManager {
    static let shared = CityCacheManager()

    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?

    private init() {
        do {
            let schema = Schema([CachedCity.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = modelContainer?.mainContext
        } catch {
            print("Failed to initialize SwiftData container: \(error)")
        }
    }

    func saveCities(_ cities: [City], for userId: UUID) {
        guard let context = modelContext else { return }

        let userIdString = userId.uuidString

        do {
            // Delete existing cities for this user
            let descriptor = FetchDescriptor<CachedCity>(
                predicate: #Predicate { $0.userId == userIdString }
            )
            let existing = try context.fetch(descriptor)
            for city in existing {
                context.delete(city)
            }

            // Insert new cities
            for city in cities {
                let cached = CachedCity(from: city, userId: userId)
                context.insert(cached)
            }

            try context.save()
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

    func clearCache(for userId: UUID) {
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
            print("Failed to clear cache: \(error)")
        }
    }
}
