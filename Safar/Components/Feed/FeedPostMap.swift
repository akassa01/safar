//
//  FeedPostMap.swift
//  Safar
//
//  Mini map component for feed post cards showing place pins
//

import SwiftUI
import MapKit

struct FeedPostMap: View {
    let latitude: Double
    let longitude: Double
    let places: [Place]

    @State private var mapCameraPosition: MapCameraPosition

    init(latitude: Double, longitude: Double, places: [Place]) {
        self.latitude = latitude
        self.longitude = longitude
        self.places = places
        self._mapCameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )))
    }

    var body: some View {
        Map(position: $mapCameraPosition) {
            // City center marker
            Annotation("", coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) {
                Circle()
                    .fill(Color.accentColor.opacity(0.3))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.accentColor, lineWidth: 2)
                    )
            }

            // Place markers
            ForEach(places, id: \.localKey) { place in
                Annotation(place.name, coordinate: place.coordinate) {
                    Circle()
                        .fill(place.category.systemColor)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                }
            }
        }
        .frame(height: 150)
        .cornerRadius(12)
        .allowsHitTesting(false) // Non-interactive in feed card
    }
}

#Preview {
    FeedPostMap(
        latitude: 35.6762,
        longitude: 139.6503,
        places: [
            Place(
                id: 1,
                name: "Shibuya Crossing",
                latitude: 35.6595,
                longitude: 139.7004,
                category: .activity
            ),
            Place(
                id: 2,
                name: "Tsukiji Market",
                latitude: 35.6654,
                longitude: 139.7707,
                category: .restaurant
            )
        ]
    )
    .padding()
}
