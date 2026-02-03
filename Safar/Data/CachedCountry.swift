//
//  CachedCountry.swift
//  safar
//
//  SwiftData model for offline country caching
//

import Foundation
import SwiftData

@Model
final class CachedCountry {
    @Attribute(.unique) var id: Int64
    var name: String
    var countryCode: String
    var capital: String?
    var continent: String
    var population: Int64
    var averageRating: Double?
    var userId: String
    var lastUpdated: Date

    init(
        id: Int64,
        name: String,
        countryCode: String,
        capital: String?,
        continent: String,
        population: Int64,
        averageRating: Double?,
        userId: String,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.countryCode = countryCode
        self.capital = capital
        self.continent = continent
        self.population = population
        self.averageRating = averageRating
        self.userId = userId
        self.lastUpdated = lastUpdated
    }

    convenience init(from country: Country, userId: UUID) {
        self.init(
            id: country.id,
            name: country.name,
            countryCode: country.countryCode,
            capital: country.capital,
            continent: country.continent,
            population: country.population,
            averageRating: country.averageRating,
            userId: userId.uuidString
        )
    }

    func toCountry() -> Country {
        Country(
            id: id,
            name: name,
            countryCode: countryCode,
            capital: capital,
            continent: continent,
            population: population,
            averageRating: averageRating
        )
    }
}
