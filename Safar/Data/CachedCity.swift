//
//  CachedCity.swift
//  safar
//
//  SwiftData model for offline city caching
//

import Foundation
import SwiftData

@Model
final class CachedCity {
    @Attribute(.unique) var id: Int
    var displayName: String
    var admin: String
    var country: String
    var visited: Bool
    var rating: Double?
    var userId: String
    var lastUpdated: Date

    init(id: Int, displayName: String, admin: String, country: String, visited: Bool, rating: Double?, userId: String, lastUpdated: Date = Date()) {
        self.id = id
        self.displayName = displayName
        self.admin = admin
        self.country = country
        self.visited = visited
        self.rating = rating
        self.userId = userId
        self.lastUpdated = lastUpdated
    }

    convenience init(from city: City, userId: UUID) {
        self.init(
            id: city.id,
            displayName: city.displayName,
            admin: city.admin,
            country: city.country,
            visited: city.visited ?? false,
            rating: city.rating,
            userId: userId.uuidString
        )
    }

    func toCity() -> City {
        City(
            id: id,
            displayName: displayName,
            plainName: displayName,
            admin: admin,
            country: country,
            countryId: 0,
            population: 0,
            latitude: 0,
            longitude: 0,
            visited: visited,
            rating: rating,
            notes: nil,
            userId: nil,
            averageRating: nil,
            ratingCount: nil
        )
    }
}
