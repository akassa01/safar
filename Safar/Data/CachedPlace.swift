//
//  CachedPlace.swift
//  safar
//
//  SwiftData model for offline place caching
//

import Foundation
import SwiftData

@Model
final class CachedPlace {
    var id: Int
    var name: String
    var latitude: Double
    var longitude: Double
    var category: String
    var cityId: Int
    var liked: Bool?
    var userId: String
    var lastUpdated: Date

    init(
        id: Int,
        name: String,
        latitude: Double,
        longitude: Double,
        category: String,
        cityId: Int,
        liked: Bool?,
        userId: String,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.cityId = cityId
        self.liked = liked
        self.userId = userId
        self.lastUpdated = lastUpdated
    }

    convenience init(from place: Place, userId: UUID) {
        self.init(
            id: place.id ?? 0,
            name: place.name,
            latitude: place.latitude,
            longitude: place.longitude,
            category: place.category.rawValue,
            cityId: place.cityId ?? 0,
            liked: place.liked,
            userId: userId.uuidString
        )
    }

    func toPlace() -> Place {
        Place(
            id: id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            category: PlaceCategory(rawValue: category) ?? .other,
            cityId: cityId,
            userId: UUID(uuidString: userId),
            liked: liked
        )
    }
}
