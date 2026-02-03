//
//  CityPlacesViewModel.swift
//  safar
//
//  Created by Assistant on 2025-09-13.
//

import Foundation
import SwiftUI

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
        guard let userId = currentUserId else { return }
        isLoading = true
        error = nil
        isOfflineData = false

        let isOnline = NetworkMonitor.shared.isConnected

        if isOnline {
            do {
                let places = try await databaseManager.getUserPlaces(userId: userId, cityId: cityId)
                var grouped: [PlaceCategory: [Place]] = [:]
                for place in places {
                    grouped[place.category, default: []].append(place)
                }
                placesByCategory = grouped

                // Cache places for offline use
                CityCacheManager.shared.savePlaces(places, for: cityId, userId: userId)
            } catch {
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
        } catch {
            self.error = error
        }
    }
    
    func updateLiked(for placeId: Int, liked: Bool?, cityId: Int) async {
        do {
            try await databaseManager.updateUserPlaceLiked(placeId: placeId, liked: liked)
            await loadPlaces(for: cityId)
        } catch {
            self.error = error
        }
    }
    
    func deletePlace(placeId: Int, cityId: Int) async {
        do {
            try await databaseManager.deleteUserPlace(placeId: placeId)
            await loadPlaces(for: cityId)
        } catch {
            self.error = error
        }
    }
}


