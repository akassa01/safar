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
    var plainName: String
    var admin: String
    var country: String
    var countryId: Int64
    var population: Int
    var latitude: Double
    var longitude: Double
    var visited: Bool
    var rating: Double?
    var notes: String?
    var averageRating: Double?
    var ratingCount: Int?
    var userId: String
    var lastUpdated: Date

    init(
        id: Int,
        displayName: String,
        plainName: String,
        admin: String,
        country: String,
        countryId: Int64,
        population: Int,
        latitude: Double,
        longitude: Double,
        visited: Bool,
        rating: Double?,
        notes: String?,
        averageRating: Double?,
        ratingCount: Int?,
        userId: String,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.plainName = plainName
        self.admin = admin
        self.country = country
        self.countryId = countryId
        self.population = population
        self.latitude = latitude
        self.longitude = longitude
        self.visited = visited
        self.rating = rating
        self.notes = notes
        self.averageRating = averageRating
        self.ratingCount = ratingCount
        self.userId = userId
        self.lastUpdated = lastUpdated
    }

    convenience init(from city: City, userId: UUID) {
        self.init(
            id: city.id,
            displayName: city.displayName,
            plainName: city.plainName,
            admin: city.admin,
            country: city.country,
            countryId: city.countryId,
            population: city.population,
            latitude: city.latitude,
            longitude: city.longitude,
            visited: city.visited ?? false,
            rating: city.rating,
            notes: city.notes,
            averageRating: city.averageRating,
            ratingCount: city.ratingCount,
            userId: userId.uuidString
        )
    }

    func toCity() -> City {
        City(
            id: id,
            displayName: displayName,
            plainName: plainName,
            admin: admin,
            country: country,
            countryId: countryId,
            population: population,
            latitude: latitude,
            longitude: longitude,
            visited: visited,
            rating: rating,
            notes: notes,
            userId: nil,
            averageRating: averageRating,
            ratingCount: ratingCount
        )
    }
}
