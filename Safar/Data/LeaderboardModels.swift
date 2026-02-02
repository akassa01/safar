//
//  LeaderboardModels.swift
//  safar
//
//  Models for leaderboard entries (cities and countries ranked by community ratings)
//

import Foundation

// MARK: - City Leaderboard Entry
struct CityLeaderboardEntry: Codable, Identifiable, Hashable {
    let id: Int
    let displayName: String
    let admin: String
    let country: String
    let averageRating: Double
    let ratingCount: Int
    var rank: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case admin
        case country
        case averageRating = "average_rating"
        case ratingCount = "rating_count"
        case rank
    }
}

// MARK: - Country Leaderboard Entry
struct CountryLeaderboardEntry: Codable, Identifiable, Hashable {
    let id: Int64
    let name: String
    let continent: String
    let averageRating: Double
    var rank: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case continent
        case averageRating = "average_rating"
        case rank
    }
}

// MARK: - People Leaderboard Entry
struct PeopleLeaderboardEntry: Codable, Identifiable, Hashable {
    let id: String
    let username: String?
    let fullName: String?
    let avatarURL: String?
    let visitedCitiesCount: Int
    let visitedCountriesCount: Int
    var rank: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case avatarURL = "avatar_url"
        case visitedCitiesCount = "visited_cities_count"
        case visitedCountriesCount = "visited_countries_count"
        case rank
    }
}
