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
    
    private let databaseManager = DatabaseManager.shared
    private var currentUserId: UUID?
    
    func setUserId(_ userId: UUID) {
        self.currentUserId = userId
    }
    
    func loadPlaces(for cityId: Int) async {
        guard let userId = currentUserId else { return }
        isLoading = true
        error = nil
        do {
            let places = try await databaseManager.getUserPlaces(userId: userId, cityId: cityId)
            var grouped: [PlaceCategory: [Place]] = [:]
            for place in places {
                grouped[place.category, default: []].append(place)
            }
            placesByCategory = grouped
        } catch {
            self.error = error
        }
        isLoading = false
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


