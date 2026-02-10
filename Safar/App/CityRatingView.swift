//
//  CityRatingView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-11.
//

import SwiftUI
import os

struct CityRatingView: View {
    @Binding var isPresented: Bool
    
    let cityName: String
    let country: String
    let cityID: Int
    let onRatingSelected: (Double) -> Void
    
    @State private var selectedRating: Double? = nil
    @State private var currentStep: RatingStep = .categorization
    @State private var selectedCategory: CityCategory? = nil
    @State private var comparisonCities: [City] = []
    @State private var currentComparisonIndex = 0
    @State private var comparisonResults: [ComparisonResult] = []
    @State private var ratingBounds = RatingBounds()
    @State private var currentComparisonCity: City? = nil

    @State private var isFirstFiveCitiesFlow = false
    @State private var tempCityRating: Double? = nil
    @State private var isSubmitting = false
    @State private var tiedCityId: Int? = nil
    @State private var hasAdjustedRatings = false

    private let minimumCitiesForRating = 5

    @EnvironmentObject var viewModel: UserCitiesViewModel
    
    private var ratedCities: [City] {
        viewModel.visitedCities.filter { $0.id != cityID }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if ratedCities.count < minimumCitiesForRating {
                    firstCitiesView
                } else {
                    switch currentStep {
                    case .categorization:
                        categorizationView
                    case .comparison:
                        comparisonView
                    }
                }
            }
            .background(Color("Background"))
            .padding()
            .navigationTitle("Rate \(cityName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        print("Cancelling rating for ")
                        isPresented = false
                    }
                }
            }
        }
        .overlay {
            if isSubmitting {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView("Saving rating...")
                            .padding(24)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
            }
        }
        .allowsHitTesting(!isSubmitting)
        .task {
            // Ensure rated cities are loaded for comparison logic
            if viewModel.currentUserId == nil {
                await viewModel.initializeWithCurrentUser()
            }
            print("Entered city rating view")
        }
        .background(Color("Background"))
    }
    
    private var firstCitiesView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                Text("Building Your Rating System")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("Help us understand your travel preferences!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                Text("Progress: \(ratedCities.count)/\(minimumCitiesForRating)")
                    .font(.headline)
                
                ProgressView(value: Double(ratedCities.count), total: Double(minimumCitiesForRating))
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: 200)
                
                Text("After \(minimumCitiesForRating) cities, we'll reveal your personalized ratings!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if currentStep == .categorization {
                firstCitiesCategorizationView
            } else if currentStep == .comparison {
                // Show comparison view for first cities flow
                if currentComparisonCity != nil {
                    firstCitiesComparisonView
                } else {
                    Text("Calculating your rating...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .background(Color("Background"))
    }
    
    private var firstCitiesComparisonView: some View {
        VStack(spacing: 30) {
            if let comparisonCity = currentComparisonCity {
                VStack(spacing: 20) {
                    Text("Which city do you prefer?")
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 20) {
                        // New city
                        Button(action: {
                            recordFirstCitiesComparison(newCityWins: true)
                        }) {
                            CityComparisonCard(
                                name: cityName,
                                country: country,
                                rating: nil,
                                isSelected: false
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Text("vs")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        // Comparison city
                        Button(action: {
                            recordFirstCitiesComparison(newCityWins: false)
                        }) {
                            CityComparisonCard(
                                name: comparisonCity.displayName,
                                country: comparisonCity.country,
                                rating: nil,
                                isSelected: false
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    
    private var firstCitiesCategorizationView: some View {
        VStack(spacing: 16) {
            Text("How did you feel about \(cityName)?")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            ForEach(CityCategory.allCases, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                    isFirstFiveCitiesFlow = true
                    handleFirstCitiesRating(category: category)
                }) {
                    CategoryCard(
                        category: category,
                        isSelected: selectedCategory == category,
                        showRating: false
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color("Background"))
    }
    
    private var categorizationView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("How did you feel about \(cityName)?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("This helps us understand where to place it in your rankings before fine-tuning with comparisons.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                ForEach(CityCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                        currentStep = .comparison
                        startComparison()
                    }) {
                        CategoryCard(
                            category: category,
                            isSelected: selectedCategory == category,
                            showRating: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .background(Color("Background"))
    }
    
    private var comparisonView: some View {
        VStack(spacing: 30) {
            if let comparisonCity = currentComparisonCity {
                VStack(spacing: 40) {
                    Text("Which city do you prefer?")
                        .font(.title2)
                        .fontWeight(.semibold)

                    HStack(spacing: 20) {
                        // New city
                        Button(action: {
                            recordComparison(newCityWins: true)
                        }) {
                            CityComparisonCard(
                                name: cityName,
                                country: country,
                                rating: nil,
                                isSelected: false
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Text("vs")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        // Comparison city
                        Button(action: {
                            recordComparison(newCityWins: false)
                        }) {
                            CityComparisonCard(
                                name: comparisonCity.displayName,
                                country: comparisonCity.country,
                                rating: Double(comparisonCity.rating ?? 0.0),
                                isSelected: false
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    Button(action: {
                        recordTie()
                    }) {
                        Text("Can't Choose")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .background(Color("Background"))
    }
    
    private func handleFirstCitiesRating(category: CityCategory) {
        print("Rating first city in category: \(category)")
        selectedCategory = category
        tempCityRating = category.baseRating

        if ratedCities.count > 0 {
            currentStep = .comparison
            startFirstCitiesComparison()
        } else {
            selectedRating = tempCityRating
            Task {
                await completeRating()
            }
        }
    }

    private func startFirstCitiesComparison() {
        guard let category = selectedCategory else { return }
        
        let categoryRange = category.ratingRange
        let relevantCities = ratedCities.filter { city in
            guard let rating = city.rating else { return false }
            return (rating >= categoryRange.lowerBound && rating <= categoryRange.upperBound) && city.id != self.cityID
        }
        
        var citiesToCompare = relevantCities
        
        if citiesToCompare.isEmpty {
            // If no cities in same category, use all cities
            citiesToCompare = ratedCities
        }
        
        // Limit to reasonable number of comparisons
        let maxComparisons = min(ratedCities.count, 5)
        comparisonCities = Array(citiesToCompare.shuffled().prefix(maxComparisons))
        comparisonResults = []
        currentComparisonIndex = 0
        
        if let firstCity = comparisonCities.first {
            currentComparisonCity = firstCity
            currentStep = .comparison
        } else {
            selectedRating = tempCityRating
            Task {
                await completeRating()
            }
        }
    }

    private func recordFirstCitiesComparison(newCityWins: Bool) {
        guard let opponent = currentComparisonCity else { return }
        
        comparisonResults.append(.init(comparedCity: opponent, newCityWins: newCityWins))
        currentComparisonIndex += 1
        
        if currentComparisonIndex < comparisonCities.count {
            currentComparisonCity = comparisonCities[currentComparisonIndex]
        } else {
            calculateFirstCitiesRating()
        }
    }
        
    private func startComparison() {
        guard let category = selectedCategory else { return }

        let categoryRange = category.ratingRange
        ratingBounds.lowerBound = categoryRange.lowerBound
        ratingBounds.upperBound = categoryRange.upperBound

        // Find seed city: closest to category midpoint, within category range
        let seedRating = category.baseRating
        let closestCity = ratedCities
            .filter { city in
                guard let rating = city.rating else { return false }
                return rating >= categoryRange.lowerBound && rating <= categoryRange.upperBound && city.id != cityID
            }
            .min(by: { abs(($0.rating ?? 0) - seedRating) < abs(($1.rating ?? 0) - seedRating) })

        if let seed = closestCity {
            currentComparisonCity = seed
            comparisonResults = []
            currentStep = .comparison
        } else {
            // No cities in category range to compare against
            selectedRating = seedRating
            Task {
                await completeRating()
            }
        }
    }

    private func recordComparison(newCityWins: Bool) {
        guard let opponent = currentComparisonCity,
              let opponentRating = opponent.rating else {
            return
        }

        if newCityWins {
            ratingBounds.lowerBound = max(ratingBounds.lowerBound, Double(opponentRating))
        } else {
            ratingBounds.upperBound = min(ratingBounds.upperBound, Double(opponentRating))
        }

        comparisonResults.append(.init(comparedCity: opponent, newCityWins: newCityWins))

        nextComparison()
    }

    private func recordTie() {
        guard let opponent = currentComparisonCity,
              let opponentRating = opponent.rating else { return }

        selectedRating = Double(opponentRating)
        tiedCityId = opponent.id
        Task {
            await completeRating()
        }
    }

    private func nextComparison() {
        let candidates = ratedCities
            .filter {
                guard let rating = $0.rating else { return false }
                return rating > ratingBounds.lowerBound && rating < ratingBounds.upperBound
            }
            .sorted { ($0.rating ?? 0) < ($1.rating ?? 0) }

        if let median = candidates[safe: candidates.count / 2] {
            currentComparisonCity = median
        } else {
            selectedRating = (ratingBounds.lowerBound + ratingBounds.upperBound) / 2
            Task {
                await completeRating()
            }
        }
    }

    private func calculateFirstCitiesRating() {
        print("Calculating first cities rating...")
        guard let category = selectedCategory else { return }

        let wins = comparisonResults.filter { $0.newCityWins }.count
        let total = comparisonResults.count

        if total == 0 {
            selectedRating = tempCityRating
        } else {
            let winPercentage = Double(wins) / Double(total)
            let averageOpponentRating = comparisonResults.compactMap { $0.comparedCity.rating }.reduce(0.0, +) / Double(comparisonResults.count)

            // Calculate rating based on comparisons
            let baseRating = category.baseRating
            let comparisonAdjustment = (winPercentage - 0.5) * 2.0
            let opponentAdjustment = (averageOpponentRating - baseRating) * 0.3

            let calculatedRating = baseRating + comparisonAdjustment + opponentAdjustment
            selectedRating = max(1.0, min(10.0, calculatedRating))
        }

        // Ensure unique ratings for first 5 cities
        ensureUniqueRatingsForFirstCities()

        // If this will be the 5th city, prepare for rating revelation
        let shouldRevealRatings = ratedCities.count + 1 == minimumCitiesForRating

        Task {
            if shouldRevealRatings {
                await revealAllRatings()
            }
            await completeRating()
        }
    }
    
    private func ensureUniqueRatingsForFirstCities() {
        guard let newRating = selectedRating else { return }

        let existingRatings = ratedCities.compactMap { $0.rating }

        if existingRatings.contains(newRating) {
            let step = 0.1
            for attempt in 1...20 {
                let offset = step * Double((attempt + 1) / 2) * (attempt.isMultiple(of: 2) ? -1.0 : 1.0)
                let candidate = newRating + offset
                if candidate >= 1.0 && candidate <= 10.0 && !existingRatings.contains(candidate) {
                    selectedRating = candidate
                    return
                }
            }
            selectedRating = max(1.0, min(10.0, newRating + step))
        }
    }
    
    private func revealAllRatings() async {
        // This is called when the 5th city is being rated
        // adjustRatingsAroundNewCity handles both gap enforcement and scaling to 10
        await adjustRatingsAroundNewCity()
    }
    
    private func adjustRatingsAroundNewCity() async {
        guard let newRating = selectedRating else { return }
        print("Adjusting ratings around new city (order-preserving)...")

        // Build sorted list of all ratings including the new city (nil = new city)
        var all: [(city: City?, rating: Double)] = ratedCities
            .compactMap { city in city.rating.map { (city, $0) } }
        all.append((nil, newRating))
        all.sort { $0.rating < $1.rating }

        let n = all.count
        // Density-aware min gap: shrinks as cities grow, capped at 0.2
        let minGap = max(0.001, min(0.2, 10.0 / Double(n + 1)))

        // Find position of the new city
        guard let newIndex = all.firstIndex(where: { $0.city == nil }) else { return }

        // Push cities below the new city downward if too close, preserving order
        for i in stride(from: newIndex - 1, through: 0, by: -1) {
            let ceiling = all[i + 1].rating - minGap
            if all[i].rating > ceiling {
                let clamped = max(0.0001, ceiling)
                all[i] = (all[i].city, clamped)
            }
        }

        // Push cities above the new city upward if too close, preserving order
        for i in (newIndex + 1)..<n {
            let floor = all[i - 1].rating + minGap
            if all[i].rating < floor {
                let clamped = min(10.0, floor)
                all[i] = (all[i].city, clamped)
            }
        }

        // Scale so highest rating reaches 10.0 (operates on local array, not stale viewModel)
        let highestRating = all.max { $0.rating < $1.rating }?.rating ?? 0
        if highestRating < 10.0 && highestRating > 0 {
            let scaleFactor = 10.0 / highestRating
            all = all.map { ($0.city, min(10.0, $0.rating * scaleFactor)) }
        }

        // Update selectedRating from the local array (new city entry has city == nil)
        if let newEntry = all.first(where: { $0.city == nil }) {
            selectedRating = newEntry.rating
        }

        // Persist only changed ratings (skip the new city and any tied city)
        for entry in all {
            if let city = entry.city,
               let original = city.rating,
               original != entry.rating,
               city.id != tiedCityId {
                print("Adjusted rating of \(city.displayName) from \(original) to \(entry.rating)")
                await viewModel.updateCityRatingWithoutRefresh(cityId: city.id, rating: entry.rating)
            }
        }

        hasAdjustedRatings = true
    }
    
    private func completeRating() async {
        guard let rating = selectedRating else { return }
        isSubmitting = true

        if !hasAdjustedRatings {
            await adjustRatingsAroundNewCity()
        }

        // Use the potentially updated selectedRating (scaling may have changed it)
        let finalRating = selectedRating ?? rating

        // The rating update is handled by the parent view through the onRatingSelected callback
        // which uses the UserCitiesViewModel.updateCityRating() function

        await MainActor.run {
            onRatingSelected(finalRating)
        }

        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        await MainActor.run {
            isPresented = false
        }
    }
    
    private func findCityByID(_ id: Int) -> City? {
        ratedCities.first(where: { $0.id == id })
    }
}

enum RatingStep {
    case categorization
    case comparison
}


struct ComparisonResult {
    let comparedCity: City
    let newCityWins: Bool
}

struct RatingBounds {
    var lowerBound: Double = 1.0
    var upperBound: Double = 10.0
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

//#Preview {
//    @Previewable @State var isPresented: Bool = true
//    CityRatingView(isPresented: $isPresented, cityName: "Vancouver", country: "Canada", cityID: "1234", onRatingSelected: {_ in })
//}
