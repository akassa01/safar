//
//  CityPhoto.swift
//  Safar
//

import Foundation
import SwiftUI

// MARK: - CityPhoto Model

/// Represents a cached city photo stored in Supabase
struct CityPhoto: Codable, Identifiable, PhotoAttributable {
    let id: Int64
    let cityId: Int
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
        case cityId = "city_id"
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

// MARK: - CityPhoto Insert Payload

/// Insert payload for creating city photos
struct CityPhotoInsert: Codable {
    let cityId: Int
    let unsplashId: String
    let photoURLRegular: String
    let photoURLSmall: String
    let blurHash: String?
    let photographerName: String
    let photographerUsername: String
    let unsplashURL: String

    enum CodingKeys: String, CodingKey {
        case cityId = "city_id"
        case unsplashId = "unsplash_id"
        case photoURLRegular = "photo_url_regular"
        case photoURLSmall = "photo_url_small"
        case blurHash = "blur_hash"
        case photographerName = "photographer_name"
        case photographerUsername = "photographer_username"
        case unsplashURL = "unsplash_url"
    }

    /// Create insert payload from Unsplash API response
    init(cityId: Int, from unsplashPhoto: UnsplashPhoto) {
        self.cityId = cityId
        self.unsplashId = unsplashPhoto.id
        self.photoURLRegular = unsplashPhoto.urls.regular
        self.photoURLSmall = unsplashPhoto.urls.small
        self.blurHash = unsplashPhoto.blurHash
        self.photographerName = unsplashPhoto.user.name
        self.photographerUsername = unsplashPhoto.user.username
        self.unsplashURL = unsplashPhoto.links.html
    }
}

// MARK: - CityPhoto ViewModel

@MainActor
class CityPhotoViewModel: ObservableObject {
    @Published var cityPhoto: CityPhoto?
    @Published var isLoading = false
    @Published var error: String?

    private let unsplashService = UnsplashService.shared

    /// In-memory cache to avoid redundant loads during session
    private static var photoCache: [Int: CityPhoto] = [:]

    /// Load photo for a city - checks Supabase cache first, then fetches from Unsplash
    func loadPhoto(for cityId: Int, cityName: String, country: String) async {
        // Check in-memory cache first
        if let cached = Self.photoCache[cityId] {
            self.cityPhoto = cached
            return
        }

        isLoading = true
        error = nil

        do {
            // Step 1: Check Supabase for cached photo
            if let cachedPhoto = try await fetchCachedPhoto(cityId: cityId) {
                self.cityPhoto = cachedPhoto
                Self.photoCache[cityId] = cachedPhoto
                isLoading = false
                return
            }

            // Step 2: No cache - fetch from Unsplash
            guard let unsplashPhoto = try await unsplashService.searchCityPhoto(
                cityName: cityName,
                country: country
            ) else {
                // No photo found - not an error, just no banner
                isLoading = false
                return
            }

            // Step 3: Save to Supabase cache
            let savedPhoto = try await saveCityPhoto(cityId: cityId, from: unsplashPhoto)
            self.cityPhoto = savedPhoto
            Self.photoCache[cityId] = savedPhoto

        } catch {
            self.error = error.localizedDescription
            print("CityPhotoViewModel error: \(error)")
        }

        isLoading = false
    }

    /// Fetch cached photo from Supabase
    private func fetchCachedPhoto(cityId: Int) async throws -> CityPhoto? {
        let response: [CityPhoto] = try await supabase
            .from("city_photos")
            .select()
            .eq("city_id", value: cityId)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    /// Save photo to Supabase cache
    private func saveCityPhoto(cityId: Int, from unsplashPhoto: UnsplashPhoto) async throws -> CityPhoto {
        let insert = CityPhotoInsert(cityId: cityId, from: unsplashPhoto)

        let response: CityPhoto = try await supabase
            .from("city_photos")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    /// Clear in-memory cache (for memory pressure)
    static func clearCache() {
        photoCache.removeAll()
    }
}
