//
//  CityOverviewViewModel.swift
//  Safar
//
//  ViewModel for the community-focused city overview screen
//

import Foundation
import SwiftUI

@MainActor
class CityOverviewViewModel: ObservableObject {
    @Published var city: City?
    @Published var friendsWhoVisited: [FriendCityVisit] = []
    @Published var userStatus: UserCityStatus = .notAdded
    @Published var isLoading = true
    @Published var error: String?

    private let databaseManager = DatabaseManager.shared

    func loadData(cityId: Int) async {
        isLoading = true
        error = nil

        do {
            // Load city data
            city = try await databaseManager.getCityById(cityId: cityId)

            // Load current user's status and friends who visited
            if let currentUserId = databaseManager.getCurrentUserId() {
                async let statusTask = databaseManager.getUserCityStatus(cityId: cityId, userId: currentUserId)
                async let friendsTask = databaseManager.getFriendsWhoVisitedCity(cityId: cityId, userId: currentUserId)

                let (status, friends) = try await (statusTask, friendsTask)
                self.userStatus = status
                self.friendsWhoVisited = friends
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func refreshUserStatus(cityId: Int) async {
        guard let currentUserId = databaseManager.getCurrentUserId() else { return }

        do {
            userStatus = try await databaseManager.getUserCityStatus(cityId: cityId, userId: currentUserId)
        } catch {
            print("Failed to refresh user status: \(error)")
        }
    }
}
