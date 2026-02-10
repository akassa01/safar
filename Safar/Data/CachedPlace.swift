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
    var userPlaceId: Int
    var name: String
    var latitude: Double
    var longitude: Double
    var category: String
    var cityId: Int
    var likes: Int
    var liked: Bool?
    var userId: String
    var mapKitId: String
    var lastUpdated: Date

    init(
        id: Int,
        userPlaceId: Int,
        name: String,
        latitude: Double,
        longitude: Double,
        category: String,
        cityId: Int,
        likes: Int,
        liked: Bool?,
        userId: String,
        mapKitId: String = "",
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.userPlaceId = userPlaceId
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.cityId = cityId
        self.likes = likes
        self.liked = liked
        self.userId = userId
        self.mapKitId = mapKitId
        self.lastUpdated = lastUpdated
    }

    convenience init(from place: Place, userId: UUID) {
        self.init(
            id: place.id ?? 0,
            userPlaceId: place.userPlaceId ?? 0,
            name: place.name,
            latitude: place.latitude,
            longitude: place.longitude,
            category: place.category.rawValue,
            cityId: place.cityId ?? 0,
            likes: place.likes,
            liked: place.liked,
            userId: userId.uuidString,
            mapKitId: place.mapKitId
        )
    }

    func toPlace() -> Place {
        Place(
            id: id,
            userPlaceId: userPlaceId,
            name: name,
            latitude: latitude,
            longitude: longitude,
            category: PlaceCategory(rawValue: category) ?? .other,
            cityId: cityId,
            likes: likes,
            userId: UUID(uuidString: userId),
            liked: liked,
            mapKitId: mapKitId
        )
    }
}
