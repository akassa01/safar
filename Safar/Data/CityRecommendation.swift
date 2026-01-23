//
//  CityRecommendation.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-08.
//

import Foundation
import FoundationModels

// MARK: - Foundation Models Response Types

@Generable
struct AIRecommendationResponse {
    @Guide(description: "Array of exactly 10 city recommendations based on user preferences")
    let recommendations: [RecommendedCity]
}

@Generable
struct RecommendedCity {
    @Guide(description: "The city name only, e.g. 'Tokyo' or 'New York City'")
    let cityName: String

    @Guide(description: "The country name, e.g. 'Japan' or 'United States'")
    let country: String

    @Guide(description: "A brief 1-sentence reason why this city matches the user's travel preferences")
    let matchReason: String
}

// MARK: - Cached Recommendation Model

struct CityRecommendation: Codable, Identifiable {
    let id: Int
    let displayName: String
    let country: String
    let admin: String
    let matchReason: String
    let latitude: Double
    let longitude: Double
}

// MARK: - Recommendation Errors

enum RecommendationError: LocalizedError {
    case insufficientCities(current: Int, required: Int)
    case modelUnavailable
    case matchingFailed
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .insufficientCities(let current, let required):
            return "Visit and rate at least \(required) cities to unlock recommendations. You've visited \(current) so far."
        case .modelUnavailable:
            return "AI recommendations are currently unavailable."
        case .matchingFailed:
            return "Could not find matching cities in our database."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
