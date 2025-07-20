//
//  VisitedCity.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-05.
//

import Foundation
import SwiftData
import CoreLocation
import SwiftUI

@Model
class City {
    var name: String
    var admin: String
    var country: String
    var latitude: Double
    var longitude: Double
    
    var bucketList: Bool
    var isVisited: Bool
    
    var rating: Double?
    var notes: String?
    @Relationship(deleteRule: .cascade) var photos: [Photo] = []
    @Relationship(deleteRule: .cascade) var places: [Place] = []

    init(name: String, latitude: Double, longitude: Double, bucketList: Bool, isVisited: Bool, country: String, admin: String) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.bucketList = bucketList
        self.isVisited = isVisited
        self.country = country
        self.admin = admin
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var uniqueID: String { // theres an id already in the db
        "\(name)-\(String(longitude))-\(String(latitude))"
    }
}
