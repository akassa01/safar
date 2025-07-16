//
//  Place.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-09.
//

import SwiftData
import Foundation

@Model
class Place {
    var id: UUID = UUID()
    var name: String
    var latitude: Double
    var longitude: Double
    var category: PlaceCategory
    var city: City?

    init(name: String, latitude: Double, longitude: Double, category: PlaceCategory, city: City? = nil) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.city = city
    }
}

enum PlaceCategory: String, Codable, CaseIterable {
    case hotel
    case restaurant
    case activity
    case shop
    
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
        case .hotel: return "bed.double"
        case .restaurant: return "fork.knife"
        case .activity: return "figure.walk"
        case .shop: return "bag"
        }
    }
    
    var color: String {
        switch self {
        case .hotel: return "blue"
        case .restaurant: return "orange"
        case .activity: return "green"
        case .shop: return "purple"
        }
    }
}
