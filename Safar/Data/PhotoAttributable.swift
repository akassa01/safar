//
//  PhotoAttributable.swift
//  Safar
//

import Foundation

/// Shared protocol for Unsplash photo attribution (used by CityPhoto and CountryPhoto)
protocol PhotoAttributable {
    var photographerName: String { get }
    var photographerUsername: String { get }
    var unsplashURL: String { get }
    var photoURLRegular: String { get }
}

extension PhotoAttributable {
    var attributionText: String {
        "Photo by \(photographerName) on Unsplash"
    }

    var photographerURL: URL? {
        URL(string: "https://unsplash.com/@\(photographerUsername)?utm_source=safar&utm_medium=referral")
    }

    var photoPageURL: URL? {
        URL(string: unsplashURL + "?utm_source=safar&utm_medium=referral")
    }
}
