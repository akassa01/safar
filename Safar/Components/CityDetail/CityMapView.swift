//
//  CityMapView.swift
//  Safar
//
//  Reusable map component for displaying a city with place markers
//

import SwiftUI
import MapKit

struct CityMapView: View {
    let latitude: Double
    let longitude: Double
    let places: [Place]
    let height: CGFloat
    let isInteractive: Bool

    @State private var mapCameraPosition: MapCameraPosition
    @State private var selectedPlace: Place?

    init(latitude: Double, longitude: Double, places: [Place], height: CGFloat = 220, isInteractive: Bool = true) {
        self.latitude = latitude
        self.longitude = longitude
        self.places = places
        self.height = height
        self.isInteractive = isInteractive
        self._mapCameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )))
    }

    var body: some View {
        VStack(spacing: 0) {
            Map(position: $mapCameraPosition, selection: $selectedPlace) {
                ForEach(places, id: \.localKey) { place in
                    Annotation(place.name, coordinate: place.coordinate) {
                        Circle()
                            .fill(place.category.systemColor)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .popover(
                                isPresented: Binding(
                                    get: { selectedPlace == place },
                                    set: { if !$0 { selectedPlace = nil } }
                                ),
                                arrowEdge: .bottom
                            ) {
                                VStack(spacing: 12) {
                                    Text(place.name)
                                        .font(.headline)
                                    Button {
                                        openInAppleMaps(place: place)
                                        selectedPlace = nil
                                    } label: {
                                        Label("Open in Apple Maps", systemImage: "map")
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .padding()
                                .presentationCompactAdaptation(.popover)
                            }
                    }
                    .tag(place)
                }
            }
            .frame(height: height)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .allowsHitTesting(isInteractive)

            if isInteractive {
                HStack {
                    Button(action: {
                        withAnimation {
                            mapCameraPosition = .region(MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                            ))
                        }
                    }) {
                        Label("Reset View", systemImage: "location.circle")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .cornerRadius(16)
                    }
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
    }

    private func openInAppleMaps(place: Place) {
        let encodedName = place.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(encodedName)&ll=\(place.latitude),\(place.longitude)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    CityMapView(
        latitude: 35.6762,
        longitude: 139.6503,
        places: [
            Place(id: 1, name: "Shibuya Crossing", latitude: 35.6595, longitude: 139.7004, category: .activity),
            Place(id: 2, name: "Tsukiji Market", latitude: 35.6654, longitude: 139.7707, category: .restaurant)
        ]
    )
    .padding()
}
