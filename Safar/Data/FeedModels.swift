//
//  FeedModels.swift
//  Safar
//
//  Created by Claude on 2026-02-03.
//

import Foundation

// MARK: - Feed Post Model
struct FeedPost: Identifiable, Hashable {
    let id: Int64  // user_city.id
    let userId: String
    let cityId: Int
    let cityName: String
    let cityAdmin: String
    let cityCountry: String
    let cityLatitude: Double
    let cityLongitude: Double
    let rating: Double?
    let notes: String?
    let visitedAt: Date

    // User profile data
    var username: String?
    var fullName: String?
    var avatarURL: String?

    // Aggregated counts (set after fetch)
    var likeCount: Int = 0
    var commentCount: Int = 0
    var isLikedByCurrentUser: Bool = false

    // Places (fetched separately)
    var places: [Place] = []

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FeedPost, rhs: FeedPost) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Post Comment Model
struct PostComment: Codable, Identifiable {
    let id: Int64
    let userCityId: Int64
    let userId: String
    let content: String
    let createdAt: Date

    // User profile data (set after fetch)
    var username: String?
    var fullName: String?
    var avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userCityId = "user_city_id"
        case userId = "user_id"
        case content
        case createdAt = "created_at"
    }
}

// MARK: - Post Like Model
struct PostLike: Codable, Identifiable {
    let id: Int64
    let userCityId: Int64
    let userId: String
    let createdAt: Date

    // User profile data (set after fetch)
    var username: String?
    var fullName: String?
    var avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userCityId = "user_city_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

// MARK: - Internal Response Types for Database Queries
extension FeedPost {
    /// Response structure for fetching feed posts from Supabase
    struct FeedPostResponse: Codable {
        let id: Int64
        let userId: String
        let visited: Bool
        let rating: Double?
        let notes: String?
        let visitedAt: Date?
        let cities: CityData

        struct CityData: Codable {
            let id: Int
            let displayName: String
            let admin: String
            let country: String
            let latitude: Double
            let longitude: Double

            enum CodingKeys: String, CodingKey {
                case id
                case displayName = "display_name"
                case admin
                case country
                case latitude
                case longitude
            }
        }

        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case visited
            case rating
            case notes
            case visitedAt = "visited_at"
            case cities = "city_id"
        }
    }

    /// Create FeedPost from database response
    init(from response: FeedPostResponse) {
        self.id = response.id
        self.userId = response.userId
        self.cityId = response.cities.id
        self.cityName = response.cities.displayName
        self.cityAdmin = response.cities.admin
        self.cityCountry = response.cities.country
        self.cityLatitude = response.cities.latitude
        self.cityLongitude = response.cities.longitude
        self.rating = response.rating
        self.notes = response.notes
        self.visitedAt = response.visitedAt ?? Date()
    }

    /// Create FeedPost from a friend's city visit
    init(from friendVisit: FriendCityVisit, city: City) {
        self.id = Int64(friendVisit.id) ?? 0
        self.userId = friendVisit.userId
        self.cityId = city.id
        self.cityName = city.displayName
        self.cityAdmin = city.admin
        self.cityCountry = city.country
        self.cityLatitude = city.latitude
        self.cityLongitude = city.longitude
        self.rating = friendVisit.rating
        self.notes = friendVisit.notes
        self.visitedAt = friendVisit.visitedAt ?? Date()
        self.username = friendVisit.username
        self.fullName = friendVisit.fullName
        self.avatarURL = friendVisit.avatarURL
    }
}
