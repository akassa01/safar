//
//  Photo.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-10.
//


import Foundation
// import SwiftData
import UIKit

// @Model
// class Photo {
//     var id: UUID
//     var imageData: Data
//     var dateAdded: Date
//     var city: City?

//     init(image: UIImage, city: City?) {
//         self.id = UUID()
//         self.imageData = image.jpegData(compressionQuality: 0.8) ?? Data()
//         self.dateAdded = Date()
//         self.city = city
//     }

//     var image: UIImage? {
//         UIImage(data: imageData)
//     }
// }

// Struct version for future Supabase implementation
struct Photo: Codable, Identifiable {
    let id: Int
    let imageData: Data
    let dateAdded: Date
    let cityId: Int
    let userId: UUID
    
    enum CodingKeys: String, CodingKey {
        case id
        case imageData = "image_data"
        case dateAdded = "date_added"
        case cityId = "city_id"
        case userId = "user_id"
    }
    
    var image: UIImage? {
        UIImage(data: imageData)
    }
}
