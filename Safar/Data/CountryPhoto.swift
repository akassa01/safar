//
//  CountryPhoto.swift
//  Safar
//

import Foundation
import SwiftUI

// MARK: - CountryPhoto Model

/// Represents a cached country photo stored in Supabase
struct CountryPhoto: Codable, Identifiable, PhotoAttributable {
    let id: Int
    let countryId: Int
    let unsplashId: String
    let photoURLRegular: String
    let photoURLSmall: String
    let blurHash: String?
    let photographerName: String
    let photographerUsername: String
    let unsplashURL: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case countryId = "country_id"
        case unsplashId = "unsplash_id"
        case photoURLRegular = "photo_url_regular"
        case photoURLSmall = "photo_url_small"
        case blurHash = "blur_hash"
        case photographerName = "photographer_name"
        case photographerUsername = "photographer_username"
        case unsplashURL = "unsplash_url"
        case createdAt = "created_at"
    }
}

// MARK: - CountryPhoto Insert Payload

struct CountryPhotoInsert: Codable {
    let countryId: Int
    let unsplashId: String
    let photoURLRegular: String
    let photoURLSmall: String
    let blurHash: String?
    let photographerName: String
    let photographerUsername: String
    let unsplashURL: String

    enum CodingKeys: String, CodingKey {
        case countryId = "country_id"
        case unsplashId = "unsplash_id"
        case photoURLRegular = "photo_url_regular"
        case photoURLSmall = "photo_url_small"
        case blurHash = "blur_hash"
        case photographerName = "photographer_name"
        case photographerUsername = "photographer_username"
        case unsplashURL = "unsplash_url"
    }

    init(countryId: Int, from unsplashPhoto: UnsplashPhoto) {
        self.countryId = countryId
        self.unsplashId = unsplashPhoto.id
        self.photoURLRegular = unsplashPhoto.urls.regular
        self.photoURLSmall = unsplashPhoto.urls.small
        self.blurHash = unsplashPhoto.blurHash
        self.photographerName = unsplashPhoto.user.name
        self.photographerUsername = unsplashPhoto.user.username
        self.unsplashURL = unsplashPhoto.links.html
    }
}

// MARK: - CountryPhoto ViewModel

@MainActor
class CountryPhotoViewModel: ObservableObject {
    @Published var countryPhoto: CountryPhoto?
    @Published var isLoading = false
    @Published var error: String?

    private let unsplashService = UnsplashService.shared

    private static var photoCache: [Int: CountryPhoto] = [:]

    func loadPhoto(for countryId: Int, countryName: String) async {
        if let cached = Self.photoCache[countryId] {
            self.countryPhoto = cached
            return
        }

        isLoading = true
        error = nil

        do {
            if let cachedPhoto = try await fetchCachedPhoto(countryId: countryId) {
                self.countryPhoto = cachedPhoto
                Self.photoCache[countryId] = cachedPhoto
                isLoading = false
                return
            }

            guard let unsplashPhoto = try await unsplashService.searchCountryPhoto(
                countryName: countryName
            ) else {
                isLoading = false
                return
            }

            let savedPhoto = try await saveCountryPhoto(countryId: countryId, from: unsplashPhoto)
            self.countryPhoto = savedPhoto
            Self.photoCache[countryId] = savedPhoto

        } catch {
            self.error = error.localizedDescription
            print("CountryPhotoViewModel error: \(error)")
        }

        isLoading = false
    }

    private func fetchCachedPhoto(countryId: Int) async throws -> CountryPhoto? {
        let response: [CountryPhoto] = try await supabase
            .from("country_photos")
            .select()
            .eq("country_id", value: countryId)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    private func saveCountryPhoto(countryId: Int, from unsplashPhoto: UnsplashPhoto) async throws -> CountryPhoto {
        let insert = CountryPhotoInsert(countryId: countryId, from: unsplashPhoto)

        let response: CountryPhoto = try await supabase
            .from("country_photos")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    static func clearCache() {
        photoCache.removeAll()
    }
}
