//
//  PlaceSearchView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-11.
//

import SwiftUI
import MapKit

struct PlaceSearchView: View {
    @Environment(\.dismiss) private var dismiss
    
    let cityCoordinate: CLLocationCoordinate2D
    let category: PlaceCategory
    let onPlacesSelected: ([Place]) -> Void
    
    @State private var placeRatings: [String: Bool] = [:]
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedPlaces: Set<String> = []
    @State private var allSelectedPlaces: [String: MKMapItem] = [:]
    @State private var isSearching = false
    @State private var region: MKCoordinateRegion
    
    init(cityCoordinate: CLLocationCoordinate2D, category: PlaceCategory, onPlacesSelected: @escaping ([Place]) -> Void) {
        self.cityCoordinate = cityCoordinate
        self.category = category
        self.onPlacesSelected = onPlacesSelected
        
        _region = State(initialValue: MKCoordinateRegion(
            center: cityCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText, onSearchButtonClicked: performSearch)
                
                if isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "magnifyingglass",
                        description: Text("Try searching for \(category.rawValue)s in this area")
                    )
                } else {
                    List(searchResults, id: \.self) { mapItem in
                        let mapKitId = mapItem.identifier?.stringValue ?? ""
                        PlaceRowView(
                            mapItem: mapItem,
                            category: category,
                            isSelected: selectedPlaces.contains(mapKitId),
                            rating: placeRatings[mapKitId],
                            onTap: {
                                togglePlaceSelection(mapItem)
                            },
                            onRatingChanged: { newRating in
                                placeRatings[mapKitId] = newRating
                            }
                        )
                        .listRowBackground(Color("Background"))
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color("Background"))
            .navigationTitle("Add \(category.rawValue.capitalized)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveSelectedPlaces()
                    }
                    .fontWeight(.semibold)
                    .disabled(allSelectedPlaces.isEmpty)
                }
            }
            .onAppear {
                performCategorySearch()
            }
        }
    }
    
    private func togglePlaceSelection(_ mapItem: MKMapItem) {
        let mapKitId = mapItem.identifier?.stringValue ?? ""
        if selectedPlaces.contains(mapKitId) {
            selectedPlaces.remove(mapKitId)
            allSelectedPlaces.removeValue(forKey: mapKitId)
        } else {
            selectedPlaces.insert(mapKitId)
            allSelectedPlaces[mapKitId] = mapItem
        }
    }

    private func saveSelectedPlaces() {
        let places = allSelectedPlaces.map { (mapKitId, mapItem) -> Place in
            Place(
                name: mapItem.name ?? "Unknown",
                latitude: mapItem.placemark.coordinate.latitude,
                longitude: mapItem.placemark.coordinate.longitude,
                category: category,
                liked: placeRatings[mapKitId],
                mapKitId: mapKitId
            )
        }
        onPlacesSelected(places)
        dismiss()
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            DispatchQueue.main.async {
                isSearching = false
                if let response = response {
                    searchResults = response.mapItems.filter { mapItem in
                        filterByCategory(mapItem)
                    }
                } else {
                    searchResults = []
                }
                updateSelectedPlacesForCurrentResults()
            }
        }
    }
    
    private func performCategorySearch() {
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = getCategorySearchTerm()
        request.region = region
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            DispatchQueue.main.async {
                isSearching = false
                if let response = response {
                    searchResults = response.mapItems.filter { mapItem in
                        filterByCategory(mapItem)
                    }
                } else {
                    searchResults = []
                }
                updateSelectedPlacesForCurrentResults()
            }
        }
    }
    
    private func updateSelectedPlacesForCurrentResults() {
        selectedPlaces.removeAll()
        for mapItem in searchResults {
            let mapKitId = mapItem.identifier?.stringValue ?? ""
            if allSelectedPlaces.keys.contains(mapKitId) {
                selectedPlaces.insert(mapKitId)
            }
        }
    }
    
    private func getCategorySearchTerm() -> String {
        switch category {
        case .restaurant:
            return "restaurants"
        case .hotel:
            return "hotels"
        case .activity:
            return "attractions"
        case .shop:
            return "shopping"
        case .nightlife:
            return "nightlife"
        case .other:
            return "points of interest"
        }
    }
    
    private func filterByCategory(_ mapItem: MKMapItem) -> Bool {
        guard let pointOfInterestCategory = mapItem.pointOfInterestCategory else { return true }
        switch category {
        case .restaurant:
            return [.restaurant, .cafe, .bakery, .brewery, .winery, .foodMarket, .distillery].contains(pointOfInterestCategory)
        case .hotel:
            return [.hotel].contains(pointOfInterestCategory)
        case .activity:
            return [.museum, .park, .zoo, .amusementPark, .theater, .movieTheater, .stadium, .nightlife, .musicVenue, .library, .castle, .fortress, .landmark, .nationalMonument, .beauty, .spa, .aquarium, .fairground, .beach, .campground, .marina, .nationalPark, .rvPark, .fishing, .kayaking, .surfing, .swimming, .baseball, .basketball, .bowling, .goKart, .golf, .hiking, .miniGolf, .rockClimbing, .skatePark, .skiing, .soccer, .tennis, .volleyball, .fireStation, .planetarium, .bank, .school, .university].contains(pointOfInterestCategory)
        case .shop:
            return [.store, .gasStation, .bakery, .pharmacy, .bank, .atm].contains(pointOfInterestCategory)
        case .nightlife:
            return [.nightlife, .brewery, .winery, .distillery].contains(pointOfInterestCategory)
        case .other:
            return true
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.accent)
            TextField("Search places...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    onSearchButtonClicked()
                }
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button("Search") {
                    onSearchButtonClicked()
                }
                .bold()
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color("Background"))
    }
}

extension CLPlacemark {
    var formattedAddress: String? {
        guard let subThoroughfare = subThoroughfare,
              let thoroughfare = thoroughfare,
              let locality = locality else {
            return [thoroughfare, locality].compactMap { $0 }.joined(separator: ", ")
        }
        return "\(subThoroughfare) \(thoroughfare), \(locality)"
    }
}

extension MKMapItem.Identifier {
    var stringValue: String {
        (self as any RawRepresentable).rawValue as! String
    }
}

// Preview intentionally omitted to reduce build-time complexity
