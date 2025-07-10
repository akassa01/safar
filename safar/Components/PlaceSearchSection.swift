//
//  PlaceSearchSection.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-09.
//

import SwiftUI
import MapKit

struct PlaceSearchSection: View {
    var title: String
    var category: PlaceCategory
    @Binding var results: [Place]
    
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []

    var body: some View {
        Section(header: Text(title)) {
            TextField("Search for \(title.lowercased())", text: $searchText)
                .onSubmit {
                    search()
                }

            ForEach(searchResults, id: \.self) { item in
                Button(action: {
                    let place = Place(
                        name: item.name ?? "Unknown",
                        latitude: item.placemark.coordinate.latitude,
                        longitude: item.placemark.coordinate.longitude,
                        category: category
                    )
                    results.append(place)
                    searchText = ""
                    searchResults = []
                }) {
                    VStack(alignment: .leading) {
                        Text(item.name ?? "Unknown")
                        Text(item.placemark.title ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if !results.isEmpty {
                ForEach(results, id: \.id) { place in
                    HStack {
                        Text(place.name)
                        Spacer()
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
    }

    private func search() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        let search = MKLocalSearch(request: request)
        Task {
            let response = try? await search.start()
            self.searchResults = response?.mapItems ?? []
        }
    }
}
