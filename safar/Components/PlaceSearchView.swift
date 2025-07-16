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
    
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedPlaces: Set<String> = []
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
                        PlaceRowView(
                            mapItem: mapItem,
                            category: category,
                            isSelected: selectedPlaces.contains(mapItem.name ?? "")
                        ) {
                            togglePlaceSelection(mapItem)
                        }
                    }
                }
            }
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
                    .disabled(selectedPlaces.isEmpty)
                }
            }
            .onAppear {
                performCategorySearch()
            }
        }
    }
    
    private func togglePlaceSelection(_ mapItem: MKMapItem) {
        let placeName = mapItem.name ?? ""
        if selectedPlaces.contains(placeName) {
            selectedPlaces.remove(placeName)
        } else {
            selectedPlaces.insert(placeName)
        }
    }
    
    private func saveSelectedPlaces() {
        let places = searchResults.compactMap { mapItem -> Place? in
            guard selectedPlaces.contains(mapItem.name ?? "") else { return nil }
            return Place(
                name: mapItem.name ?? "Unknown",
                latitude: mapItem.placemark.coordinate.latitude,
                longitude: mapItem.placemark.coordinate.longitude,
                category: category
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
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                
                if let response = response {
                    searchResults = response.mapItems.filter { mapItem in
                        filterByCategory(mapItem)
                    }
                } else {
                    searchResults = []
                }
            }
        }
    }
    
    private func performCategorySearch() {
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = getCategorySearchTerm()
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                
                if let response = response {
                    searchResults = response.mapItems.filter { mapItem in
                        filterByCategory(mapItem)
                    }
                } else {
                    searchResults = []
                }
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
            return [.store,.gasStation, .bakery, .pharmacy, .bank, .atm].contains(pointOfInterestCategory)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search places...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    onSearchButtonClicked()
                }
            
            if !text.isEmpty {
                Button("Search") {
                    onSearchButtonClicked()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

struct PlaceRowView: View {
    let mapItem: MKMapItem
    let category: PlaceCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading) {
                    Image(systemName: iconForCategory(category))
                        .foregroundColor(colorForCategory(category))
                        .font(.title2)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mapItem.name ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let address = mapItem.placemark.formattedAddress {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    if let category = mapItem.pointOfInterestCategory {
                        Text(category.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.title2)
            }
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconForCategory(_ category: PlaceCategory) -> String {
        switch category {
        case .restaurant: return "fork.knife"
        case .hotel: return "bed.double"
        case .activity: return "figure.walk"
        case .shop: return "cart.fill"
        }
    }
    
    private func colorForCategory(_ category: PlaceCategory) -> Color {
        switch category {
        case .restaurant: return .orange
        case .hotel: return .blue
        case .activity: return .green
        case .shop: return .purple
        }
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

#Preview {
    PlaceSearchView(
        cityCoordinate: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207),
        category: .restaurant,
        onPlacesSelected: { _ in }
    )
}
