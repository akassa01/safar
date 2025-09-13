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
struct Place: Codable, Identifiable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let category: PlaceCategory
    let cityId: Int
    let userId: UUID
    let liked: Bool?
    
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
}

enum PlaceCategory: String, Codable, CaseIterable, Identifiable {
    case restaurant
    case hotel
    case activity
    case shop
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .hotel: return "Hotel"
        case .restaurant: return "Restaurant"
        case .activity: return "Activity"
        case .shop: return "Shop"
        }
    }
    
    var pluralDisplayName: String {
        switch self {
        case .hotel: return "Hotels"
        case .restaurant: return "Restaurants"
        case .activity: return "Activities"
        case .shop: return "Shops"
        }
    }
    
    var icon: String {
        switch self {
        case .hotel: return "bed.double.fill"
        case .restaurant: return "fork.knife"
        case .activity: return "popcorn"
        case .shop: return "bag"
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
        }
    }
}
