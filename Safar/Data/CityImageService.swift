//
//  CityImageService.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-08.
//

import Foundation
import ImagePlayground
import UIKit

@MainActor
class CityImageService: ObservableObject {
    static let shared = CityImageService()

    @Published var imageCache: [Int: UIImage] = [:]
    @Published var loadingIds: Set<Int> = []

    private var imageCreator: ImageCreator?
    private let cacheDirectory: URL

    private init() {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("CityImages")

        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func getImage(for city: CityRecommendation) -> UIImage? {
        if let cached = imageCache[city.id] {
            return cached
        }

        if let diskCached = loadCachedImage(for: city.id) {
            imageCache[city.id] = diskCached
            return diskCached
        }

        return nil
    }

    func loadImageIfNeeded(for city: CityRecommendation) async {
        if imageCache[city.id] != nil { return }
        if loadingIds.contains(city.id) { return }

        if let diskCached = loadCachedImage(for: city.id) {
            imageCache[city.id] = diskCached
            return
        }

        loadingIds.insert(city.id)

        do {
            if let image = try await generateCityImage(for: city) {
                imageCache[city.id] = image
            }
        } catch {
            print("Image generation failed for \(city.displayName): \(error)")
        }

        loadingIds.remove(city.id)
    }

    private func generateCityImage(for city: CityRecommendation) async throws -> UIImage? {

        if imageCreator == nil {
            imageCreator = try await ImageCreator()
        }

        guard let creator = imageCreator else {
            return nil
        }

        guard !creator.availableStyles.isEmpty else {
            print("No styles available - Image Playground models may not be downloaded")
            return nil
        }

        let style: ImagePlaygroundStyle = creator.availableStyles.contains(.animation)
            ? .animation
            : creator.availableStyles.first!

        // Use just the city name - simple and direct
        let prompt = "\(city.displayName) skyline"

        let images = creator.images(
            for: [.text(prompt)],
            style: style,
            limit: 1
        )

        for try await generatedImage in images {
            let uiImage = UIImage(cgImage: generatedImage.cgImage)
            saveCachedImage(uiImage, for: city.id)
            return uiImage
        }

        return nil
    }

    private func cacheURL(for cityId: Int) -> URL {
        cacheDirectory.appendingPathComponent("city_\(cityId).jpg")
    }

    private func loadCachedImage(for cityId: Int) -> UIImage? {
        let url = cacheURL(for: cityId)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    private func saveCachedImage(_ image: UIImage, for cityId: Int) {
        let url = cacheURL(for: cityId)
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: url)
        }
    }

    func clearCache() {
        imageCache.removeAll()
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}
