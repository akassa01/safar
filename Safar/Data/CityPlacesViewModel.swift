//
//  CityPlacesViewModel.swift
//  safar
//
//  Created by Assistant on 2025-09-13.
//

import Foundation
import SwiftUI
import os

@MainActor
class CityPlacesViewModel: ObservableObject {
    @Published var placesByCategory: [PlaceCategory: [Place]] = [:]
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isOfflineData = false

    private let databaseManager = DatabaseManager.shared
    private var currentUserId: UUID?

    func setUserId(_ userId: UUID) {
        self.currentUserId = userId
    }

    func loadPlaces(for cityId: Int) async {
        guard let userId = currentUserId else {
            print("🔴 loadPlaces: no currentUserId set, returning early")
            return
        }
        print("🔍 loadPlaces: cityId=\(cityId), userId=\(userId)")
        isLoading = true
        error = nil
        isOfflineData = false

        let isOnline = NetworkMonitor.shared.isConnected
        print("🔍 loadPlaces: isOnline=\(isOnline)")

        if isOnline {
            do {
                let places = try await databaseManager.getUserPlaces(userId: userId, cityId: cityId)
                print("🔍 loadPlaces: got \(places.count) places from DB")
                var grouped: [PlaceCategory: [Place]] = [:]
                for place in places {
                    grouped[place.category, default: []].append(place)
                }
                placesByCategory = grouped
                print("🔍 loadPlaces: grouped into \(grouped.count) categories: \(grouped.map { "\($0.key.rawValue): \($0.value.count)" })")

                // Cache places for offline use
                CityCacheManager.shared.savePlaces(places, for: cityId, userId: userId)
            } catch {
                print("🔴 loadPlaces error: \(error)")
                self.error = error
                // Fallback to cache on error
                loadFromCache(cityId: cityId, userId: userId)
            }
        } else {
            // Offline: load from cache
            loadFromCache(cityId: cityId, userId: userId)
        }
        isLoading = false
    }

    private func loadFromCache(cityId: Int, userId: UUID) {
        let cachedPlaces = CityCacheManager.shared.loadPlaces(for: cityId, userId: userId)

        if !cachedPlaces.isEmpty {
            var grouped: [PlaceCategory: [Place]] = [:]
            for place in cachedPlaces {
                grouped[place.category, default: []].append(place)
            }
            placesByCategory = grouped
            isOfflineData = true
            print("Loaded \(cachedPlaces.count) places from cache for city \(cityId)")
        }
    }
    
    func addPlaces(_ places: [Place], to cityId: Int) async {
        guard let userId = currentUserId else { return }
        do {
            try await databaseManager.insertUserPlaces(userId: userId, cityId: cityId, places: places)
            await loadPlaces(for: cityId)
            for place in places {
                AnalyticsManager.shared.capture("place_added", properties: [
                    "category": place.category.rawValue,
                    "city_id": cityId,
                    "places_added_count": places.count
                ])
            }
        } catch {
            Log.data.error("addPlaces failed for cityId \(cityId): \(error)")
            self.error = error
        }
    }

    func updateLiked(for userPlaceId: Int, liked: Bool?, cityId: Int) async {
        let place = placesByCategory.values.flatMap { $0 }.first(where: { $0.userPlaceId == userPlaceId })
        do {
            try await databaseManager.updateUserPlaceLiked(userPlaceId: userPlaceId, liked: liked)
            await loadPlaces(for: cityId)
            if let liked = liked, let place = place {
                AnalyticsManager.shared.capture("place_liked", properties: [
                    "category": place.category.rawValue,
                    "city_id": cityId,
                    "liked": liked
                ])
            }
        } catch {
            Log.data.error("updateLiked failed for userPlaceId \(userPlaceId): \(error)")
            self.error = error
        }
    }

    func deletePlace(userPlaceId: Int, cityId: Int) async {
        let place = placesByCategory.values.flatMap { $0 }.first(where: { $0.userPlaceId == userPlaceId })
        do {
            try await databaseManager.deleteUserPlace(userPlaceId: userPlaceId)
            await loadPlaces(for: cityId)
            if let place = place {
                AnalyticsManager.shared.capture("place_removed", properties: [
                    "category": place.category.rawValue,
                    "city_id": cityId
                ])
            }
        } catch {
            Log.data.error("deletePlace failed for userPlaceId \(userPlaceId): \(error)")
            self.error = error
        }
    }
}


