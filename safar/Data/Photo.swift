//
//  Photo.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-10.
//


import Foundation
import SwiftData
import UIKit

@Model
class Photo {
    var id: UUID
    var imageData: Data
    var dateAdded: Date
    var city: City?

    init(image: UIImage, city: City?) {
        self.id = UUID()
        self.imageData = image.jpegData(compressionQuality: 0.8) ?? Data()
        self.dateAdded = Date()
        self.city = city
    }

    var image: UIImage? {
        UIImage(data: imageData)
    }
}
