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

    enum CodingKeys: String, CodingKey {
      case username
      case fullName = "full_name"
      case avatarURL = "avatar_url"
    }
  }

struct ProfileSearchResult: Codable, Identifiable {
    let id: String
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


