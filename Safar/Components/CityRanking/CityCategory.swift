//
//  CityCategory.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-16.
//
import Foundation
import SwiftUI

enum CityCategory: String, CaseIterable {
    case loved = "Absolutely Loved It"
    case enjoyed = "Really Enjoyed It"
    case decent = "It Was Decent"
    case disappointed = "A Bit Disappointed"
    case disliked = "Didn't Like It"
    
    var icon: String {
        switch self {
        case .loved: return "heart.fill"
        case .enjoyed: return "hand.thumbsup.fill"
        case .decent: return "hand.raised.fill"
        case .disappointed: return "hand.thumbsdown.fill"
        case .disliked: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .loved: return .red
        case .enjoyed: return .green
        case .decent: return .orange
        case .disappointed: return .purple
        case .disliked: return .gray
        }
    }
    
    var baseRating: Double {
        switch self {
        case .loved: return 9.5
        case .enjoyed: return 8.25
        case .decent: return 6.25
        case .disappointed: return 3.25
        case .disliked: return 1.25
        }
    }
    
    var ratingRange: ClosedRange<Double> {
        switch self {
        case .loved: return 9.0...10.0
        case .enjoyed: return 7.5...9.0
        case .decent: return 5.0...7.5
        case .disappointed: return 2.5...5.0
        case .disliked: return 0.000001...2.5
        }
    }
    
    var description: String {
        switch self {
        case .loved: return "One of your favorite places"
        case .enjoyed: return "Had a great time overall"
        case .decent: return "Nice enough, nothing special"
        case .disappointed: return "Expected more from it"
        case .disliked: return "Wouldn't recommend or return"
        }
    }
}

extension CityCategory {
    static func fromRating(_ rating: Double) -> CityCategory {
        switch rating {
        case 9.0...10.0: return .loved
        case 7.5..<9.0: return .enjoyed
        case  5.0..<7.5: return .decent
        case 2.5..<5.0: return .disappointed
        default: return .disliked
        }
    }
}
