//
//  RecommendationsViewModel.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-08.
//

import Foundation

@MainActor
class RecommendationsViewModel: ObservableObject {
    @Published var recommendations: [CityRecommendation] = []
    @Published var isLoading = false
    @Published var error: RecommendationError?
    @Published var hasLoadedFromCache = false

    private let cacheKey = "city_recommendations_cache"
    private let cacheTimestampKey = "city_recommendations_timestamp"
    private let service = RecommendationService.shared

    var minimumCitiesRequired: Int {
        RecommendationService.minimumCitiesRequired
    }

    func loadCachedRecommendations() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode([CityRecommendation].self, from: data) else {
            return
        }
        self.recommendations = cached
        self.hasLoadedFromCache = true
    }

    func generateRecommendations(
        visitedCities: [City],
        excludingPreviousRecommendations: [CityRecommendation] = []
    ) async {
        guard visitedCities.count >= minimumCitiesRequired else {
            self.error = .insufficientCities(
                current: visitedCities.count,
                required: minimumCitiesRequired
            )
            return
        }

        isLoading = true
        error = nil

        do {
            let newRecommendations = try await service.generateRecommendations(
                from: visitedCities,
                excludingPreviousRecommendations: excludingPreviousRecommendations
            )
            self.recommendations = newRecommendations
            saveToCache(newRecommendations)
            self.hasLoadedFromCache = true
        } catch let recommendationError as RecommendationError {
            self.error = recommendationError
        } catch {
            self.error = .networkError(error.localizedDescription)
        }

        isLoading = false
    }

    func reload(visitedCities: [City]) async {
        let previousRecommendations = recommendations
        clearCache()
        await generateRecommendations(
            visitedCities: visitedCities,
            excludingPreviousRecommendations: previousRecommendations
        )
    }

    private func saveToCache(_ recommendations: [CityRecommendation]) {
        guard let data = try? JSONEncoder().encode(recommendations) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
        UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)
    }

    private func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
        hasLoadedFromCache = false
        recommendations = []
    }
}
