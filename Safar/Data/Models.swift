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

// MARK: - Notifications

/// Nested actor profile returned inside an AppNotification.
struct ActorProfile: Codable {
    let id: String?
    let username: String?
    let fullName: String?
    let avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case avatarURL = "avatar_url"
    }
}

/// A single in-app notification row from the `notifications` table.
struct AppNotification: Codable, Identifiable {
    let id: Int64
    let type: String
    let read: Bool
    let createdAt: String
    let actor: ActorProfile?
    /// Contextual reference for deep-linking:
    ///   post_liked / post_commented / comment_liked / comment_replied → user_city.id
    ///   city_ranked                                                   → cities.id
    ///   new_follower / contact_joined                                 → nil (actor info suffices)
    let referenceId: Int64?
    /// City name stored at notification-creation time (city_ranked, post_liked, post_commented).
    let cityName: String?
    /// Short text preview stored at creation time (post_commented, comment_liked, comment_replied).
    let contentPreview: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case read
        case createdAt = "created_at"
        case actor
        case referenceId = "reference_id"
        case cityName = "city_name"
        case contentPreview = "content_preview"
    }
}

// MARK: - People Search

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
    var avatarURL: String?
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
