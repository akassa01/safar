//
//  Models.swift
//  Safar
//
//  Created by Arman Kassam on 2025-07-29.
//

struct Profile: Codable {
    let username: String?
    let fullName: String?
    let avatarURL: String?
    let bio: String?
    let phone: String?
    let phoneHash: String?
    let onboardingCompleted: Bool?
    let visitedCitiesCount: Int?
    let visitedCountriesCount: Int?

    enum CodingKeys: String, CodingKey {
      case username
      case fullName = "full_name"
      case avatarURL = "avatar_url"
      case bio
      case phone
      case phoneHash = "phone_hash"
      case onboardingCompleted = "onboarding_completed"
      case visitedCitiesCount = "visited_cities_count"
      case visitedCountriesCount = "visited_countries_count"
    }
  }

struct ProfileSearchResult: Codable, Identifiable {
    let id: String
    let username: String?
    let fullName: String?
    let avatarURL: String?
    let visitedCitiesCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case avatarURL = "avatar_url"
        case visitedCitiesCount = "visited_cities_count"
    }
}

// User displayed in follow lists
struct FollowUser: Codable, Identifiable {
    let id: String
    let username: String?
    let fullName: String?
    let avatarURL: String?
    let visitedCitiesCount: Int?
    var isFollowing: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case avatarURL = "avatar_url"
        case visitedCitiesCount = "visited_cities_count"
        case isFollowing = "is_following"
    }
}

// Full user profile for UserProfileView
struct UserProfile: Codable, Identifiable {
    let id: String
    let username: String?
    let fullName: String?
    let avatarURL: String?
    let bio: String?
    let phone: String?
    let phoneHash: String?
    let onboardingCompleted: Bool?
    let visitedCitiesCount: Int?
    let visitedCountriesCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case avatarURL = "avatar_url"
        case bio
        case phone
        case phoneHash = "phone_hash"
        case onboardingCompleted = "onboarding_completed"
        case visitedCitiesCount = "visited_cities_count"
        case visitedCountriesCount = "visited_countries_count"
    }
}
