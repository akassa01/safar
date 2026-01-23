//
//  RecommendationService.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-08.
//

import Foundation
import FoundationModels

@MainActor
class RecommendationService {
    static let shared = RecommendationService()

    private let databaseManager = DatabaseManager.shared
    static let minimumCitiesRequired = 10

    private init() {}

    func generateRecommendations(
        from visitedCities: [City],
        excludingPreviousRecommendations: [CityRecommendation] = []
    ) async throws -> [CityRecommendation] {
        guard visitedCities.count >= Self.minimumCitiesRequired else {
            throw RecommendationError.insufficientCities(
                current: visitedCities.count,
                required: Self.minimumCitiesRequired
            )
        }

        let previousCityNames = excludingPreviousRecommendations.map { $0.displayName }
        let prompt = buildPrompt(from: visitedCities, excludingCities: previousCityNames)

        let session = LanguageModelSession()
        let response = try await session.respond(
            to: prompt,
            generating: AIRecommendationResponse.self
        )

        var excludedIds = Set(visitedCities.map { $0.id })
        excludedIds.formUnion(excludingPreviousRecommendations.map { $0.id })

        let recommendations = await matchCitiesToDatabase(
            response.content.recommendations,
            excludingCityIds: excludedIds
        )

        guard !recommendations.isEmpty else {
            throw RecommendationError.matchingFailed
        }

        return recommendations
    }

    private func buildPrompt(from cities: [City], excludingCities: [String] = []) -> String {
        let cityList = cities
            .sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
            .map { city -> String in
                if let rating = city.rating {
                    return "\(city.displayName), \(city.country) (Rating: \(String(format: "%.1f", rating))/10)"
                } else {
                    return "\(city.displayName), \(city.country) (unrated)"
                }
            }
            .joined(separator: "\n")

        var exclusionNote = ""
        if !excludingCities.isEmpty {
            exclusionNote = "\n- Do NOT recommend these previously suggested cities: \(excludingCities.joined(separator: ", "))"
        }

        return """
        Based on these cities I have visited and their ratings:

        \(cityList)

        Recommend 10 cities I should visit next. Consider:
        - Cities similar to my highly-rated ones
        - A mix of popular and hidden gem destinations
        - Geographic diversity across different continents
        - Do NOT recommend any cities from my visited list above\(exclusionNote)

        IMPORTANT: Use full official city names only. Do NOT use abbreviations or acronyms (e.g., use "New York City" not "NYC", use "Los Angeles" not "LA").

        For each recommendation, provide a brief reason why it matches my travel preferences.
        """
    }

    private func matchCitiesToDatabase(
        _ aiCities: [RecommendedCity],
        excludingCityIds: Set<Int>
    ) async -> [CityRecommendation] {
        var matched: [CityRecommendation] = []
        var seenIds: Set<Int> = excludingCityIds

        print("[Recommendations] Attempting to match \(aiCities.count) AI recommendations")

        for aiCity in aiCities {
            // Use fuzzy search for better matching
            guard let searchResults = try? await databaseManager.searchCitiesFuzzy(
                query: aiCity.cityName,
                similarityThreshold: 0.25
            ), !searchResults.isEmpty else {
                print("[Recommendations] REJECTED: '\(aiCity.cityName), \(aiCity.country)' - no fuzzy results found")
                continue
            }

            // Find best match considering country
            let aiCountryLower = aiCity.country.lowercased()
            let bestMatch = searchResults.first { result in
                let dbCountryLower = result.country.lowercased()
                return dbCountryLower.contains(aiCountryLower) || aiCountryLower.contains(dbCountryLower)
            } ?? searchResults.first

            guard let match = bestMatch,
                  let cityId = Int(match.data_id) else {
                print("[Recommendations] REJECTED: '\(aiCity.cityName), \(aiCity.country)' - could not parse city ID")
                continue
            }

            if seenIds.contains(cityId) {
                print("[Recommendations] REJECTED: '\(aiCity.cityName), \(aiCity.country)' - already in list (duplicate or visited)")
                continue
            }

            seenIds.insert(cityId)

            let recommendation = CityRecommendation(
                id: cityId,
                displayName: match.title,
                country: match.country,
                admin: match.admin,
                matchReason: aiCity.matchReason,
                latitude: match.latitude ?? 0,
                longitude: match.longitude ?? 0
            )
            matched.append(recommendation)
            print("[Recommendations] MATCHED: '\(aiCity.cityName), \(aiCity.country)' -> '\(match.title), \(match.country)' (id: \(cityId))")
        }

        print("[Recommendations] Total matched: \(matched.count)/\(aiCities.count)")
        return matched
    }
}
