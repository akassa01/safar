//
//  CityRatingView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-11.
//

import SwiftUI
import SwiftData

struct CityRatingView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<City> { $0.isVisited == true && $0.rating != nil})
    private var allRatedCities: [City]
    
    let cityName: String
    let country: String
    let cityID: String
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
    
    private let minimumCitiesForRating = 5
    private var ratedCities: [City] {
        allRatedCities.filter { $0.uniqueID != cityID }
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
                        isPresented = false
                    }
                }
            }
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
                                name: comparisonCity.name,
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
                            print("\(comparisonCity.name) \(comparisonCity.country)")
                            recordComparison(newCityWins: false)
                        }) {
                            CityComparisonCard(
                                name: comparisonCity.name,
                                country: comparisonCity.country,
                                rating: comparisonCity.rating,
                                isSelected: false
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .background(Color("Background"))
    }
    
    private func handleFirstCitiesRating(category: CityCategory) {
        selectedCategory = category
        tempCityRating = category.baseRating
        
        if ratedCities.count > 0 {
            currentStep = .comparison
            startFirstCitiesComparison()
        } else {
            selectedRating = tempCityRating
            completeRating()
        }
    }

    private func startFirstCitiesComparison() {
        guard let category = selectedCategory else { return }
        
        let categoryRange = category.ratingRange
        let relevantCities = ratedCities.filter { city in
            guard let rating = city.rating else { return false }
            return (rating >= categoryRange.lowerBound && rating <= categoryRange.upperBound) && city.uniqueID != self.cityID
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
            // No cities to compare with - shouldn't happen but handle gracefully
            selectedRating = tempCityRating
            completeRating()
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

        ratingBounds.lowerBound = 0.0000001
        ratingBounds.upperBound = 10.0000001

        // Closest to category midpoint
        let seedRating = category.baseRating
        let closestCity = ratedCities
            .filter { $0.rating != nil }
//            .filter { $0.uniqueID != uniqueID }
            .min(by: { abs(($0.rating ?? 0) - seedRating) < abs(($1.rating ?? 0) - seedRating) })

        if let seed = closestCity {
            currentComparisonCity = seed
            comparisonResults = []
            currentStep = .comparison
        } else {
            // No cities to compare
            selectedRating = seedRating
            applyDynamicRatingAdjustments()
            completeRating()
        }
    }


    
    private func recordComparison(newCityWins: Bool) {
        guard let opponent = currentComparisonCity,
              let opponentRating = opponent.rating else {
            return
        }

        if newCityWins {
            ratingBounds.lowerBound = max(ratingBounds.lowerBound, opponentRating)
        } else {
            ratingBounds.upperBound = min(ratingBounds.upperBound, opponentRating)
        }

        comparisonResults.append(.init(comparedCity: opponent, newCityWins: newCityWins))

        nextComparison()
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
            completeRating()
        }
    }

    
    private func calculateFirstCitiesRating() {
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
        if ratedCities.count + 1 == minimumCitiesForRating {
            revealAllRatings()
        }
        
        completeRating()
    }
    
    private func ensureUniqueRatingsForFirstCities() {
        guard let newRating = selectedRating else { return }
        
        let existingRatings = ratedCities.compactMap { $0.rating }
        
        if existingRatings.contains(newRating) {
            var adjustedRating = newRating
            let increment = 0.1
            var attempts = 0
            
            while existingRatings.contains(adjustedRating) && attempts < 20 {
                adjustedRating += increment
                if adjustedRating > 10.0 {
                    adjustedRating = newRating - increment
                }
                attempts += 1
            }
            
            selectedRating = max(1.0, min(10.0, adjustedRating))
        }
    }
    
    private func revealAllRatings() {
        // This is called when the 5th city is being rated
        // Perform final adjustments to all ratings
        ensureBestCityHas10()
        
        // Apply any final scaling or adjustments
        normalizeRatingsDistribution()
        
        // Note: Don't save here - let completeRating() handle the saving
        // The new city needs to be saved along with the rating adjustments
    }
    
    private func normalizeRatingsDistribution() {
        // Ensure good distribution across the rating scale
        var allRatings: [(city: City?, rating: Double)] = []
        
        for city in ratedCities {
            if let rating = city.rating {
                allRatings.append((city: city, rating: rating))
            }
        }
        
        if let newRating = selectedRating {
            allRatings.append((city: nil, rating: newRating))
        }
        
        allRatings.sort { $0.rating < $1.rating }
        
        // Ensure minimum gaps between ratings
        let minGap = 0.1
        for i in 1..<allRatings.count {
            let currentRating = allRatings[i].rating
            let previousRating = allRatings[i-1].rating
            
            if currentRating - previousRating < minGap {
                let adjustment = minGap - (currentRating - previousRating)
                let newRating = min(10.0, currentRating + adjustment)
                
                if let city = allRatings[i].city {
                    city.rating = newRating
                } else {
                    selectedRating = newRating
                }
                
                allRatings[i] = (city: allRatings[i].city, rating: newRating)
            }
        }
    }
    
    private func calculateFinalRating() {
        guard let category = selectedCategory else { return }
        
        let wins = comparisonResults.filter { $0.newCityWins }.count
        let total = comparisonResults.count
        
        if total == 0 {
            selectedRating = category.baseRating
        } else {
            let winPercentage = Double(wins) / Double(total)
            let averageOpponentRating = comparisonResults.compactMap { $0.comparedCity.rating }.reduce(0.0, +) / Double(comparisonResults.count)
            
            let baseRating = category.baseRating
            let comparisonAdjustment = (winPercentage - 0.5) * 2.0
            let opponentAdjustment = (averageOpponentRating - baseRating) * 0.3
            
            let finalRating = baseRating + comparisonAdjustment + opponentAdjustment
            selectedRating = max(1.0, min(10.0, finalRating))
        }
        
        applyDynamicRatingAdjustments()
        ensureUniqueRatings()
        
        completeRating()
    }
    
    private func applyDynamicRatingAdjustments() {
        guard let newRating = selectedRating else { return }
        print("Dynamically adjusting ratings...")
        
        let adjustmentFactor = 0.1
        
        for city in ratedCities {
            guard let currentRating = city.rating else { continue }
            
            let distance = abs(currentRating - newRating)
            if distance <= 2.0 {
                let adjustment = adjustmentFactor * (2.0 - distance) / 2.0
                
                if currentRating > newRating {
                    city.rating = min(10.0, currentRating + adjustment)
                } else {
                    city.rating = max(0.1, currentRating - adjustment)
                }
            }
        }
        
        ensureBestCityHas10()
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save dynamic rating adjustments: \(error)")
        }
    }
    
    private func ensureBestCityHas10() {
        var allRatings: [(city: City?, rating: Double)] = []
        for city in ratedCities {
            if let rating = city.rating {
                allRatings.append((city: city, rating: rating))
            }
        }
        if let newRating = selectedRating {
            allRatings.append((city: nil, rating: newRating))
        }
        
        let highestRating = allRatings.max { $0.rating < $1.rating }?.rating ?? 0
        
        if highestRating < 10.0 {
            let scaleFactor = 10.0 / highestRating
            
            for city in ratedCities {
                if let rating = city.rating {
                    city.rating = min(10.0, rating * scaleFactor)
                }
            }
            
            if let newRating = selectedRating {
                selectedRating = min(10.0, newRating * scaleFactor)
            }
        }
    }
    
    private func ensureUniqueRatings() {
        guard let newRating = selectedRating else { return }
        
        let existingRatings = ratedCities.compactMap { $0.rating }
        
        if existingRatings.contains(newRating) {
            var adjustedRating = newRating
            let increment = 0.1
            var attempts = 0
            
            while existingRatings.contains(adjustedRating) && attempts < 20 {
                adjustedRating += increment
                if adjustedRating > 10.0 {
                    adjustedRating = newRating - 2.0 * increment
                }
                attempts += 1
            }
            
            selectedRating = max(1.0, min(10.0, adjustedRating))
        }
    }
    
    private func completeRating() {
        guard let rating = selectedRating else { return }
        
        if let city = findCityByName(cityName) {
                city.rating = rating
                do {
                    try modelContext.save()
                } catch {
                    print("Failed to save city rating: \(error)")
                }
            }
        
        onRatingSelected(rating)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isPresented = false
        }
    }
    
    private func findCityByName(_ name: String) -> City? {
        ratedCities.first(where: { $0.name == name })
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
//
//#Preview {
//    @Previewable @State var isPresented: Bool = true
//    CityRatingView(isPresented: $isPresented, cityName: "Vancouver", cityCountry: "Canada", cityAdmin: "British Columbia", onRatingSelected: {_ in })
//}
