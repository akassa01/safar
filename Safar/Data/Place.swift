//
//  Place.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-09.
//

import Foundation
import MapKit
import SwiftUI

// MARK: - PlaceData (maps to `places` table)
struct PlaceData: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let category: PlaceCategory
    let cityId: Int
    let likes: Int
    let mapKitId: String

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, category
        case cityId = "city_id"
        case likes
        case mapKitId = "map_kit_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        category = try container.decode(PlaceCategory.self, forKey: .category)
        cityId = try container.decode(Int.self, forKey: .cityId)
        likes = try container.decodeIfPresent(Int.self, forKey: .likes) ?? 0
        mapKitId = try container.decodeIfPresent(String.self, forKey: .mapKitId) ?? ""
    }
}

// MARK: - UserPlaceResponse (maps to user_place join query)
struct UserPlaceResponse: Codable {
    let id: Int
    let userId: String
    let liked: Bool?
    let places: PlaceData

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case liked
        case places = "place_id"
    }
}

// MARK: - Place (app-facing model, combines both tables)
struct Place: Codable, Identifiable, Hashable {
    var id: Int?            // places.id
    var userPlaceId: Int?   // user_place.id (for update/delete)
    var name: String
    var latitude: Double
    var longitude: Double
    var category: PlaceCategory
    var cityId: Int?
    var likes: Int
    var userId: UUID?
    var liked: Bool?
    var mapKitId: String

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, category, likes, liked
        case userPlaceId = "user_place_id"
        case cityId = "city_id"
        case userId = "user_id"
        case mapKitId = "map_kit_id"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var localKey: String {
        mapKitId.isEmpty ? "\(name)_\(latitude)_\(longitude)_\(category.rawValue)" : mapKitId
    }

    /// Create from a DB join response
    init(from response: UserPlaceResponse) {
        self.id = response.places.id
        self.userPlaceId = response.id
        self.name = response.places.name
        self.latitude = response.places.latitude
        self.longitude = response.places.longitude
        self.category = response.places.category
        self.cityId = response.places.cityId
        self.likes = response.places.likes
        self.userId = UUID(uuidString: response.userId)
        self.liked = response.liked
        self.mapKitId = response.places.mapKitId
    }

    /// Create from UI (e.g. MapKit search results)
    init(
        id: Int? = nil,
        userPlaceId: Int? = nil,
        name: String,
        latitude: Double,
        longitude: Double,
        category: PlaceCategory,
        cityId: Int? = nil,
        likes: Int = 0,
        userId: UUID? = nil,
        liked: Bool? = nil,
        mapKitId: String = ""
    ) {
        self.id = id
        self.userPlaceId = userPlaceId
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.cityId = cityId
        self.likes = likes
        self.userId = userId
        self.liked = liked
        self.mapKitId = mapKitId
    }
}

enum PlaceCategory: String, Codable, CaseIterable, Identifiable {
    case restaurant
    case hotel
    case activity
    case shop
    case nightlife
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hotel: return "Hotel"
        case .restaurant: return "Food & Drink"
        case .activity: return "Activity"
        case .shop: return "Shop"
        case .nightlife: return "Nightlife"
        case .other: return "Other"
        }
    }

    var pluralDisplayName: String {
        switch self {
        case .hotel: return "Hotels"
        case .restaurant: return "Food & Drink"
        case .activity: return "Activities"
        case .shop: return "Shops"
        case .nightlife: return "Nightlife"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .hotel: return "bed.double.fill"
        case .restaurant: return "fork.knife"
        case .activity: return "popcorn"
        case .shop: return "bag"
        case .nightlife: return "wineglass.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var systemColor: Color {
        switch self {
        case .restaurant:
            return .orange
        case .hotel:
            return .purple
        case .activity:
            return .green
        case .shop:
            return .yellow
        case .nightlife:
            return .pink
        case .other:
            return .blue
        }
    }
}
