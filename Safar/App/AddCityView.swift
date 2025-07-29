//
//  AddCityView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-11.
//

import SwiftUI
import SwiftData
import MapKit
import PhotosUI


struct AddCityView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let baseResult: SearchResult
    let isVisited: Bool
    let onSave: (City) -> Void
    
    @State private var activePlaceCategory: PlaceCategory? = nil
    @State private var notes: String = ""
    @State private var showingRating = false
    @State private var selectedRating: Double? = nil
    @State private var showingPlaceSearch = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var loadedImages: [UIImage] = []
    
    // Place arrays
    @State private var restaurants: [Place] = []
    @State private var hotels: [Place] = []
    @State private var activities: [Place] = []
    @State private var shops: [Place] = []
    
    var body: some View {
        NavigationView {
            Form {
                CityDetailsSection(baseResult: baseResult) .listRowBackground(Color(.accent).opacity(0.07))
                
                NotesSection(notes: $notes)
                    .listRowBackground(Color(.accent).opacity(0.07))
                
                PhotosSection(
                    selectedPhotos: $selectedPhotos,
                    loadedImages: $loadedImages
                )
                .listRowBackground(Color(.accent).opacity(0.07))
                
                PlacesSection(
                    restaurants: $restaurants,
                    hotels: $hotels,
                    activities: $activities,
                    shops: $shops,
                    onAddPlaces: { category in
                        activePlaceCategory = category
                    }
                )
                .listRowBackground(Color(.accent).opacity(0.07))
                
                if isVisited {
                    RatingSection(
                        selectedRating: selectedRating,
                        showingRating: $showingRating
                    )
                    .listRowBackground(Color("Background"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("Background"))
            .navigationTitle("Add City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingRating) {
                let uniqueID = "\(baseResult.title)-\(String(baseResult.longitude ?? 0))-\(String(baseResult.latitude ?? 0))"
                CityRatingView( isPresented: $showingRating,
                    cityName: baseResult.title,
                    country: baseResult.country,
                    cityID: uniqueID,
                    onRatingSelected: { rating in
                        selectedRating = rating
                        saveCity()
                    }
                )
                .presentationBackground(Color("Background"))
            }
            .sheet(item: $activePlaceCategory) { category in
                PlaceSearchView(
                    cityCoordinate: CLLocationCoordinate2D(
                        latitude: baseResult.latitude ?? 0,
                        longitude: baseResult.longitude ?? 0
                    ),
                    category: category,
                    onPlacesSelected: { places in
                        addPlaces(places)
                        activePlaceCategory = nil
                    }
                )
            }
            .onChange(of: selectedPhotos) { _, newPhotos in
                loadSelectedPhotos(newPhotos)
            }
        }
    }
    
    private func addPlaces(_ places: [Place]) {
        for place in places {
            switch place.category {
            case .restaurant:
                restaurants.append(place)
            case .hotel:
                hotels.append(place)
            case .activity:
                activities.append(place)
            case .shop:
                shops.append(place)
            }
        }
    }
    
    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) {
        Task {
            var newImages: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    newImages.append(image)
                }
            }
            
            await MainActor.run {
                loadedImages = newImages
            }
        }
    }
    
    private func saveCity() {
        let newCity = City(
            name: baseResult.title,
            latitude: baseResult.latitude ?? 0,
            longitude: baseResult.longitude ?? 0,
            bucketList: false,
            isVisited: isVisited,
            country: baseResult.country,
            admin: baseResult.admin
        )
        
        // Add rating
        newCity.rating = selectedRating
        
        // Add notes
        if !notes.isEmpty {
            newCity.notes = notes
        }
        
        // Add photos
        for image in loadedImages {
            let photo = Photo(image: image, city: newCity)
            newCity.photos.append(photo)
        }
        
        // Add places
        let allPlaces = restaurants + hotels + activities + shops
        for place in allPlaces {
            place.city = newCity
            newCity.places.append(place)
        }
        
        onSave(newCity)
        dismiss()
    }
}


#Preview {
    AddCityView(
        baseResult: SearchResult(
            title: "Vancouver",
            subtitle: "British Columbia, Canada",
            latitude: 49.2827,
            longitude: -123.1207,
            population: 10000,
            country: "Canada",
            admin: "British Columbia"
        ),
        isVisited: true,
        onSave: { _ in }
    )
}
