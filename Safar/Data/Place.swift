//
//  Place.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-09.
//

// import SwiftData
import Foundation
import MapKit
import SwiftUI

// @Model
// class Place {
//     var id: UUID = UUID()
//     var name: String
//     var latitude: Double
//     var longitude: Double
//     var category: PlaceCategory
//     var city: City?
//     var liked: Bool?

//     init(name: String, latitude: Double, longitude: Double, category: PlaceCategory, city: City? = nil, liked: Bool? = nil) {
//         self.name = name
//         self.latitude = latitude
//         self.longitude = longitude
//         self.category = category
//         self.city = city
//         self.liked = liked
//     }
    
//     var coordinate: CLLocationCoordinate2D {
//         CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//     }
// }

// Struct version for future Supabase implementation
struct Place: Codable, Identifiable, Hashable {
    var id: Int?
    var name: String
    var latitude: Double
    var longitude: Double
    var category: PlaceCategory
    var cityId: Int?
    var userId: UUID?
    var liked: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case latitude
        case longitude
        case category
        case cityId = "city_id"
        case userId = "user_id"
        case liked
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // For local de-duplication when id is not yet assigned by DB
    var localKey: String {
        "\(name)_\(latitude)_\(longitude)_\(category.rawValue)"
    }
    
    init(
        id: Int? = nil,
        name: String,
        latitude: Double,
        longitude: Double,
        category: PlaceCategory,
        cityId: Int? = nil,
        userId: UUID? = nil,
        liked: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.cityId = cityId
        self.userId = userId
        self.liked = liked
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
