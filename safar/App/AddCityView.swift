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
    
    @State private var notes: String = ""
    @State private var showingRating = false
    @State private var selectedRating: Double? = nil
    @State private var showingPlaceSearch = false
    @State private var selectedPlaceCategory: PlaceCategory = .restaurant
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
                CityDetailsSection(baseResult: baseResult)
                
                if isVisited {
                    RatingSection(
                        selectedRating: selectedRating,
                        showingRating: $showingRating
                    )
                }
                
                NotesSection(notes: $notes)
                
                PhotosSection(
                    selectedPhotos: $selectedPhotos,
                    loadedImages: $loadedImages
                )
                
                PlacesSection(
                    restaurants: $restaurants,
                    hotels: $hotels,
                    activities: $activities,
                    shops: $shops,
                    onAddPlaces: { category in
                        selectedPlaceCategory = category
                        showingPlaceSearch = true
                    }
                )
            }
            .navigationTitle("Add City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCity()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedRating == nil)
                }
            }
            .sheet(isPresented: $showingRating) {
                CityRatingView( isPresented: $showingRating,
                    cityName: baseResult.title,
                    onRatingSelected: { rating in
                        selectedRating = rating
                    }
                )
            }
            .sheet(isPresented: $showingPlaceSearch) {
                PlaceSearchView(
                    cityCoordinate: CLLocationCoordinate2D(
                        latitude: baseResult.latitude ?? 0,
                        longitude: baseResult.longitude ?? 0
                    ),
                    category: selectedPlaceCategory,
                    onPlacesSelected: { places in
                        addPlaces(places)
                        showingPlaceSearch = false
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

// MARK: - Section Views

struct CityDetailsSection: View {
    let baseResult: SearchResult
    
    var body: some View {
        Section("City Details") {
            VStack(alignment: .leading) {
                Text(baseResult.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("\(baseResult.subtitle)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

struct RatingSection: View {
    let selectedRating: Double?
    @Binding var showingRating: Bool
    
    var body: some View {
        Section("Rating") {
            HStack {
                Text("Rate this city")
                Spacer()
                if let rating = selectedRating {
                    Text(String(format: "%.1f/10", rating))
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
                Button(selectedRating == nil ? "Add Rating" : "Change Rating") {
                    showingRating = true
                }
                .buttonStyle(.borderless)
                .foregroundColor(.accentColor)
            }
        }
    }
}

struct NotesSection: View {
    @Binding var notes: String
    
    var body: some View {
        Section("Notes") {
            TextEditor(text: $notes)
                .frame(minHeight: 100)
        }
    }
}

struct PhotosSection: View {
    @Binding var selectedPhotos: [PhotosPickerItem]
    @Binding var loadedImages: [UIImage]
    
    var body: some View {
        Section("Photos") {
            PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 10, matching: .images) {
                Label("Add Photos", systemImage: "photo.on.rectangle.angled")
            }
            
            if !loadedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(loadedImages.indices, id: \.self) { index in
                            PhotoThumbnail(
                                image: loadedImages[index],
                                onRemove: {
                                    loadedImages.remove(at: index)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct PhotoThumbnail: View {
    let image: UIImage
    let onRemove: () -> Void
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding(4),
                alignment: .topTrailing
            )
    }
}

struct PlacesSection: View {
    @Binding var restaurants: [Place]
    @Binding var hotels: [Place]
    @Binding var activities: [Place]
    @Binding var shops: [Place]
    let onAddPlaces: (PlaceCategory) -> Void
    
    var body: some View {
        Section("Places") {
            PlaceDisclosureGroup(
                title: "Restaurants",
                places: $restaurants,
                category: .restaurant,
                color: .orange,
                icon: "fork.knife",
                onAdd: onAddPlaces
            )
            
            PlaceDisclosureGroup(
                title: "Hotels",
                places: $hotels,
                category: .hotel,
                color: .blue,
                icon: "bed.double",
                onAdd: onAddPlaces
            )
            
            PlaceDisclosureGroup(
                title: "Activities",
                places: $activities,
                category: .activity,
                color: .green,
                icon: "figure.walk",
                onAdd: onAddPlaces
            )
            
            PlaceDisclosureGroup(
                title: "Shops",
                places: $shops,
                category: .shop,
                color: .purple,
                icon: "cart.fill",
                onAdd: onAddPlaces
            )
        }
    }
}

struct PlaceDisclosureGroup: View {
    let title: String
    @Binding var places: [Place]
    let category: PlaceCategory
    let color: Color
    let icon: String
    let onAdd: (PlaceCategory) -> Void
    
    var body: some View {
        DisclosureGroup("\(title) (\(places.count))") {
            ForEach(places, id: \.id) { place in
                PlaceRowInList(
                    place: place,
                    color: color,
                    icon: icon,
                    onRemove: {
                        places.removeAll { $0.id == place.id }
                    }
                )
            }
            
            Button("Add \(title)") {
                onAdd(category)
            }
            .foregroundColor(.accentColor)
        }
    }
}

struct PlaceRowInList: View {
    let place: Place
    let color: Color
    let icon: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(place.name)
            Spacer()
            Button("Remove") {
                onRemove()
            }
            .foregroundColor(.red)
            .font(.caption)
        }
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
