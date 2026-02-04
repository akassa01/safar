//
//  CityOverviewModels.swift
//  Safar
//
//  Models for the CityOverviewView community-focused city display
//

import Foundation

// MARK: - Friend City Visit Model
/// Represents a friend's visit to a city
struct FriendCityVisit: Identifiable {
    let id: String  // user_city.id as string for Identifiable
    let userId: String
    let username: String?
    let fullName: String?
    let avatarURL: String?
    let rating: Double?
    let visitedAt: Date?
}

// MARK: - User City Status Enum
/// Represents the current user's relationship to a city
enum UserCityStatus {
    case visited(rating: Double?, notes: String?)
    case bucketList
    case notAdded

    var isVisited: Bool {
        if case .visited = self { return true }
        return false
    }

    var isBucketList: Bool {
        if case .bucketList = self { return true }
        return false
    }

    var isNotAdded: Bool {
        if case .notAdded = self { return true }
        return false
    }
}
