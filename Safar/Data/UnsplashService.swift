//
//  UnsplashService.swift
//  Safar
//

import Foundation

// MARK: - Unsplash API Models

struct UnsplashSearchResponse: Codable {
    let total: Int
    let totalPages: Int
    let results: [UnsplashPhoto]

    enum CodingKeys: String, CodingKey {
        case total
        case totalPages = "total_pages"
        case results
    }
}

struct UnsplashPhoto: Codable {
    let id: String
    let width: Int
    let height: Int
    let blurHash: String?
    let urls: UnsplashURLs
    let user: UnsplashUser
    let links: UnsplashLinks

    enum CodingKeys: String, CodingKey {
        case id, width, height
        case blurHash = "blur_hash"
        case urls, user, links
    }
}

struct UnsplashURLs: Codable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

struct UnsplashUser: Codable {
    let name: String
    let username: String
    let links: UnsplashUserLinks
}

struct UnsplashUserLinks: Codable {
    let html: String
}

struct UnsplashLinks: Codable {
    let html: String
}

// MARK: - Unsplash Errors

enum UnsplashError: LocalizedError {
    case invalidAPIKey
    case rateLimitExceeded
    case noPhotosFound
    case networkError(String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid Unsplash API key"
        case .rateLimitExceeded:
            return "Unsplash API rate limit exceeded"
        case .noPhotosFound:
            return "No photos found for this city"
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        }
    }
}

// MARK: - Unsplash Service

class UnsplashService {
    static let shared = UnsplashService()

    private let baseURL = "https://api.unsplash.com"

    private var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "UNSPLASH_ACCESS_KEY") as? String ?? ""
    }

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    /// Search for city photos on Unsplash
    /// - Parameters:
    ///   - cityName: Name of the city to search for
    ///   - country: Country name for more specific results
    /// - Returns: First matching UnsplashPhoto or nil
    func searchCityPhoto(cityName: String, country: String? = nil) async throws -> UnsplashPhoto? {
        // Debug logging
        print("[Unsplash] API Key from Info.plist: '\(apiKey)'")
        print("[Unsplash] API Key length: \(apiKey.count)")
        print("[Unsplash] API Key isEmpty: \(apiKey.isEmpty)")

        guard !apiKey.isEmpty, apiKey != "YOUR_UNSPLASH_ACCESS_KEY_HERE" else {
            print("[Unsplash] ERROR: Invalid or missing API key")
            throw UnsplashError.invalidAPIKey
        }

        // Build search query - "cityName country cityscape" for better results
        var query = "\(cityName)"
        if let country = country {
            query += " \(country)"
        }
	query += " cityscape";

        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search/photos?query=\(encodedQuery)&orientation=landscape&per_page=1") else {
            throw UnsplashError.networkError("Invalid URL")
        }

        print("[Unsplash] Request URL: \(url)")

        var request = URLRequest(url: url)
        request.setValue("Client-ID \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw UnsplashError.networkError("Invalid response")
            }

            print("[Unsplash] Response status: \(httpResponse.statusCode)")

            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                let searchResponse = try decoder.decode(UnsplashSearchResponse.self, from: data)
                print("[Unsplash] Found \(searchResponse.total) photos")
                return searchResponse.results.first

            case 401:
                print("[Unsplash] ERROR: 401 Unauthorized - API key rejected by Unsplash")
                if let responseBody = String(data: data, encoding: .utf8) {
                    print("[Unsplash] Response body: \(responseBody)")
                }
                throw UnsplashError.invalidAPIKey
            case 403:
                print("[Unsplash] ERROR: 403 Forbidden - Rate limit exceeded")
                throw UnsplashError.rateLimitExceeded
            default:
                print("[Unsplash] ERROR: HTTP \(httpResponse.statusCode)")
                throw UnsplashError.networkError("HTTP \(httpResponse.statusCode)")
            }
        } catch let error as UnsplashError {
            throw error
        } catch let error as DecodingError {
            throw UnsplashError.decodingError(error.localizedDescription)
        } catch {
            throw UnsplashError.networkError(error.localizedDescription)
        }
    }
}
