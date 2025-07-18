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
                CityRatingView( isPresented: $showingRating,
                    cityName: baseResult.title,
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
        HStack {
            Spacer()
            Button("Rank & Save") {
                    showingRating = true
            }
            .foregroundStyle(.white)
            .font(.title3)
            .bold()
            .background(
                Rectangle()
                    .foregroundStyle(.accent)
                    .frame(width: 350, height: 40)
                    .cornerRadius(20)
            )
            Spacer()
        }
        
        
//        Section("Rating") {
//            HStack {
//                Text("Rate this city")
//                Spacer()
//                if let rating = selectedRating {
//                    Text(String(format: "%.1f/10", rating))
//                        .font(.headline)
//                        .foregroundColor(.accentColor)
//                }
//                Button(selectedRating == nil ? "Add Rating" : "Change Rating") {
//                    showingRating = true
//                }
//                .buttonStyle(.borderless)
//                .foregroundColor(.accentColor)
//            }
//        }
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
                color: .purple,
                icon: "bed.double",
                onAdd: onAddPlaces
            )
            
            PlaceDisclosureGroup(
                title: "Activities",
                places: $activities,
                category: .activity,
                color: .green,
                icon: "popcorn",
                onAdd: onAddPlaces
            )
            
            PlaceDisclosureGroup(
                title: "Shops",
                places: $shops,
                category: .shop,
                color: .yellow,
                icon: "bag",
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
            if let liked = place.liked {
                Image(systemName: liked ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                    .foregroundColor(.accent)
                    .font(.caption)
            }
            Spacer()
            Button(action: {
                onRemove()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.red)
                    .font(.caption)
            }
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
