//
//  CityDetailView.swift
//  safar
//
//  Created by Assistant on 2025-07-16.
//

import SwiftUI
import MapKit
import PhotosUI

struct CityDetailView: View {
    @StateObject private var viewModel = UserCitiesViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let cityId: Int
    @State private var city: City?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingAddCityView = false
    @State private var showingNotesEditor = false
    @State private var showingRatingView = false
    @State private var showingPhotoViewer = false
    @State private var selectedPhotoIndex = 0
    @State private var showingPhotoPicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingPlaceSearch = false
    @State private var activePlaceCategory: PlaceCategory? = nil
    @State private var selectedPlaceCategory: PlaceCategory = .restaurant
    @State private var showingDeleteConfirmation = false
    @State private var selectedPlace: Place?
    @State private var mapCameraPosition: MapCameraPosition
    
    init(cityId: Int) {
        self.cityId = cityId
        self._mapCameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )))
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading city details...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("Background"))
            } else if let city = city {
                ScrollView {
                    VStack {
                        headerSection
                        
                        if city.visited == true {
                            visitedCityContent
                        } else if city.visited == false {
                            bucketListContent
                        } else {
                            unaddedCityContent
                        }
                    }
                    .background(Color("Background"))
                }
            } else {
                VStack {
                    Text("City not found")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text(errorMessage ?? "Unknown error occurred")
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("Background"))
            }
        }
        .navigationTitle(city?.displayName ?? "City Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let city = city {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if city.visited == true || city.visited == false {
                            if (city.rating != nil) {
                                Button("Change Rating", systemImage: "pencil") {
                                    showingRatingView = true
                                }
                            }
                            Button("Delete City", systemImage: "trash", role: .destructive) {
                                showingDeleteConfirmation = true
                            }
                            
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.accent)
                    }
                }
            }
        }
        .toolbarBackground(Color("Background"))
        .sheet(isPresented: $showingAddCityView) {
            if let city = city {
                AddCityView(
                    baseResult: SearchResult(
                        title: city.displayName,
                        subtitle: "\(city.admin), \(city.country)",
                        latitude: city.latitude,
                        longitude: city.longitude,
                        population: city.population,
                        country: city.country,
                        admin: city.admin,
                        data_id: String(city.id)
                    ),
                    isVisited: true,
                    onSave: { city in
                        Task {
                            await loadCityData()
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingNotesEditor) {
            if let city = city {
                NotesEditorView(city: city)
            }
        }
        .sheet(isPresented: $showingRatingView) {
            if let city = city {
                CityRatingView(
                    isPresented: $showingRatingView,
                    cityName: city.displayName,
                    country: city.country,
                    cityID: city.id,
                    onRatingSelected: { rating in
                        Task {
                            await viewModel.updateCityRating(cityId: city.id, rating: rating)
                            print("Successfully updated city \(city.displayName), \(city.country)'s rating to \(rating) (unique ID: \(city.id))")
                        }
                    }
                )
                .presentationBackground(Color("Background"))
            }
        }
        // .sheet(isPresented: $showingPhotoViewer) {
        //     PhotoViewerView(
        //         photos: city.photos,
        //         selectedIndex: $selectedPhotoIndex
        //     )
        // }
        // .onChange(of: selectedPhotos) { oldPhotos, newPhotos in
        //     if !newPhotos.isEmpty && newPhotos != oldPhotos {
        //         loadSelectedPhotos(newPhotos)
        //     }
        // }
        // .sheet(item: $activePlaceCategory) { category in
        //     PlaceSearchView(
        //         cityCoordinate: city.coordinate,
        //         category: category,
        //         onPlacesSelected: { places in
        //             addPlaces(places)
        //             activePlaceCategory = nil
        //         }
        //     )
        // }
        .alert("Delete City", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteCity()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(city?.displayName ?? "this city")? This action cannot be undone.")
        }
        .task {
            await loadCityData()
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        if let city = city {
            VStack(spacing: 20) {
                Spacer()
                // City name and location
                VStack(spacing: 12) {
                    Text(city.displayName)
                        .font(.title)
                        .bold(true)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Rectangle().fill(Color.accent))
                        .cornerRadius(20)

                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.white.opacity(0.9))
                        Text("\(city.admin), \(city.country)")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(20)
                }
                // Status and rating section
                HStack(spacing: 16) {
                    if city.visited == true {
                        EnhancedStatusBadge(
                            icon: "checkmark.circle.fill",
                            text: "Visited",
                            color: .accent
                        )
                        
                        if let rating = city.rating {
                            if viewModel.visitedCities.count >= 5 {
                                EnhancedRatingDisplay(rating: rating)
                            } else {
                                LockDisplay()
                            }
                        }
                    } else if city.visited == false {
                        EnhancedStatusBadge(
                            icon: "star.fill",
                            text: "Bucket List",
                            color: .accent
                        )
                    }
                }
            }
        } else {
            EmptyView()
        }
    }
    
    private var visitedCityContent: some View {
        VStack(spacing: 20) {
//            mapSection
//            placesSection
            notesSection
//            photosSection
        }
        .padding()
    }
    
//    private var mapSection: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            SectionHeader(title: "City Map", icon: "map.fill")
//            
//            Map(position: $mapCameraPosition, selection: $selectedPlace) {
//                // Place markers
//                ForEach(city.places, id: \.id) { place in
//                    Marker(place.name, coordinate: place.coordinate)
//                        .tint(place.category.systemColor)
//                        .tag(place)
//                }
//            }
//            .frame(height: 200)
//            .cornerRadius(12)
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
//            )
//            
//            // Map controls
//            HStack {
//                Button(action: {
//                    withAnimation {
//                        mapCameraPosition = .region(MKCoordinateRegion(
//                            center: city.coordinate,
//                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
//                        ))
//                    }
//                }) {
//                    Label("Reset View", systemImage: "location.circle")
//                        .font(.caption)
//                        .padding(.horizontal, 12)
//                        .padding(.vertical, 6)
//                        .background(Color.accentColor.opacity(0.1))
//                        .foregroundColor(.accentColor)
//                        .cornerRadius(16)
//                }
//                
//                Spacer()
//                
//                // MAYBE WE ADD A VIEW ON SELECTED PLACE FOR LIKES BALANCE
////                if let selectedPlace = selectedPlace {
////                    Text("Selected: \(selectedPlace.name)")
////                        .font(.caption)
////                        .foregroundColor(.secondary)
////                }
//            }
//        }
//        .padding()
//        .background(Color("Background"))
//        .cornerRadius(12)
//    }
    
    private var bucketListContent: some View {
        VStack(spacing: 20) {
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    showingAddCityView = true
                }) {
                    Label("Mark as Visited", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.accent))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    removeFromBucketList()
                }) {
                    Label("Remove from Bucket List", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.accent))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            
            // Basic Info
            if let city = city, let notes = city.notes, !notes.isEmpty {
                notesSection
            }
        }
    }
    
    private var unaddedCityContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Button(action: {
                    showingAddCityView = true
                }) {
                    Label("Add to Visited", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.accent))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    addToBucketList()
                }) {
                    Label("Add to Bucket List", systemImage: "star.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.accent))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
    
//    private var photosSection: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            HStack {
//                SectionHeader(title: "Photos", icon: "photo")
//                Spacer()
//                PhotosPicker(
//                    selection: $selectedPhotos,
//                    maxSelectionCount: 10,
//                    matching: .images
//                ) {
//                    Text("Add Photos")
//                        .foregroundColor(.accentColor)
//                }
//            }
//            if city.photos.isEmpty {
//                PhotosPicker(
//                    selection: $selectedPhotos,
//                    maxSelectionCount: 10,
//                    matching: .images
//                ) {
//                    Label("Add your first photo", systemImage: "photo.badge.plus")
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.accentColor.opacity(0.1))
//                        .foregroundColor(.accentColor)
//                        .cornerRadius(8)
//                }
//            } else {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 12) {
//                        ForEach(city.photos.indices, id: \.self) { index in
//                            PhotoThumbnailView(
//                                image: city.photos[index].image,
//                                onTap: {
//                                    selectedPhotoIndex = index
//                                    showingPhotoViewer = true
//                                }
//                            )
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//            }
//        }
//        .padding()
//        .background(Color("Background"))
//        .cornerRadius(12)
//    }
    
//    private var placesSection: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            SectionHeader(title: "Places", icon: "mappin.and.ellipse")
//            
//            ForEach(PlaceCategory.allCases, id: \.self) { category in
//                let categoryPlaces = city.places.filter { $0.category == category }
//                
//                PlaceCategorySection(
//                    category: category,
//                    places: categoryPlaces,
//                    onAddPlaces: {
//                        activePlaceCategory = category
//                        showingPlaceSearch = true
//                    },
//                    onRemovePlace: { place in
//                        removePlace(place)
//                    },
//                    onPlaceSelected: { place in
//                        selectedPlace = place
//                        withAnimation {
//                            mapCameraPosition = .region(MKCoordinateRegion(
//                                center: place.coordinate,
//                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
//                            ))
//                        }
//                    }
//                )
//            }
//        }
//        .padding()
//        .background(Color("Background"))
//        .cornerRadius(12)
//    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Notes", icon: "note.text")
                Spacer()
                Button((city?.notes?.isEmpty ?? true) ? "Add Notes" : "Edit Notes") {
                    showingNotesEditor = true
                }
                .foregroundColor(.accentColor)
            }
            
            if let city = city, let notes = city.notes, !notes.isEmpty {
                Text(notes)
                    .padding()
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                    .onTapGesture {
                        showingNotesEditor = true
                    }
            } else {
                Button(action: {
                    showingNotesEditor = true
                }) {
                    Label("Add notes about your visit", systemImage: "note.text.badge.plus")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(.accentColor)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color("Background"))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Functions
    
    private func loadCityData() async {
        isLoading = true
        errorMessage = nil
        
        await viewModel.initializeWithCurrentUser()
        let loadedCity = await viewModel.getCityById(cityId: cityId)
        
        await MainActor.run {
            if let loadedCity = loadedCity {
                self.city = loadedCity
                // Update map position with city coordinates
                self.mapCameraPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: loadedCity.latitude, longitude: loadedCity.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            } else {
                self.errorMessage = "City not found in your list"
            }
            self.isLoading = false
        }
    }
    
    private func addToBucketList() {
        Task {
            await viewModel.addCityToBucketList(cityId: cityId)
        }
    }
    
    private func removeFromBucketList() {
        Task {
            await viewModel.removeCityFromList(cityId: cityId)
        }
    }
    
    
    // private func updateCity(with updatedCity: City) {
    //     city.rating = updatedCity.rating
    //     city.notes = updatedCity.notes
    //     
    //     // Add new photos
    //     for photo in updatedCity.photos {
    //         photo.city = city
    //         city.photos.append(photo)
    //     }
    //     
    //     // Add new places
    //     for place in updatedCity.places {
    //         place.city = city
    //         city.places.append(place)
    //     }
    // }
    
    // private func addPhotos(_ images: [UIImage]) {
    //     for image in images {
    //         let photo = Photo(image: image, city: city)
    //         city.photos.append(photo)
    //     }
    // }
    
    // private func addPlaces(_ places: [Place]) {
    //     for place in places {
    //         place.city = city
    //         city.places.append(place)
    //     }
    //     
    //     // Update map to show all places
    //     DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    //         updateMapRegion()
    //     }
    // }
    
    // private func updateMapRegion() {
    //     let allCoordinates = [CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude)] + city.places.map { $0.coordinate }
    //     let region = calculateRegion(for: allCoordinates)
    //     withAnimation {
    //         mapCameraPosition = .region(region)
    //     }
    // }
    
    // private func loadSelectedPhotos(_ items: [PhotosPickerItem]) {
    //     Task {
    //         var newImages: [UIImage] = []
    //         for item in items {
    //             if let data = try? await item.loadTransferable(type: Data.self),
    //                let image = UIImage(data: data) {
    //                 newImages.append(image)
    //             }
    //         }
    //         
    //         await MainActor.run {
    //             addPhotos(newImages)
    //             selectedPhotos = []
    //         }
    //     }
    // }
    
    private func calculateRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty, let city = city else {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        }
        
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min() ?? city.latitude
        let maxLat = latitudes.max() ?? city.latitude
        let minLon = longitudes.min() ?? city.longitude
        let maxLon = longitudes.max() ?? city.longitude
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.01, (maxLat - minLat) * 1.3),
            longitudeDelta: max(0.01, (maxLon - minLon) * 1.3)
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    // private func removePlace(_ place: Place) {
    //     city.places.removeAll { $0.id == place.id }
    //     modelContext.delete(place)
    //     saveContext()
    //     updateMapRegion()
    // }
    
    private func deleteCity() {
        Task {
            await viewModel.removeCityFromList(cityId: cityId)
            await MainActor.run {
                dismiss()
            }
        }
    }

    // Helper function to get all rated cities
    // private func getAllRatedCities() -> [City] {
    //     let fetchDescriptor = FetchDescriptor<City>(
    //         predicate: #Predicate<City> { $0.isVisited == true && $0.rating != nil }
    //     )
    //     
    //     do {
    //         return try modelContext.fetch(fetchDescriptor)
    //     } catch {
    //         print("Error fetching rated cities: \(error)")
    //         return []
    //     }
    // }

    // Main function to adjust ratings after deletion
    // private func adjustRatingsAfterDeletion(remainingCities: [City]) {
    //     guard !remainingCities.isEmpty else { return }
    //     
    //     print("Adjusting ratings after city deletion...")
    //     
    //     // Sort cities by current rating
    //     let sortedCities = remainingCities.sorted { ($0.rating ?? 0) < ($1.rating ?? 0) }
    //     
    //     // Handle special cases for small numbers of cities
    //     handleSpecialDeletionCases(remainingCities: remainingCities)
    //     
    //     // Ensure the highest rated city has 10.0
    //     ensureHighestRatedCityHas10(cities: sortedCities)
    // }

    // Ensure the highest rated city has 10.0 rating
    // private func ensureHighestRatedCityHas10(cities: [City]) {
    //     guard let highestRatedCity = cities.max(by: { ($0.rating ?? 0) < ($1.rating ?? 0) }),
    //           let highestRating = highestRatedCity.rating else { return }
    //     
    //     if highestRating < 10.0 {
    //         let scaleFactor = 10.0 / highestRating
    //         
    //         for city in cities {
    //             if let rating = city.rating {
    //                 city.rating = min(10.0, rating * scaleFactor)
    //             }
    //         }
    //         
    //         print("Scaled all ratings by factor: \(scaleFactor)")
    //     }
    // }


    // Additional helper function for handling special cases
    // private func handleSpecialDeletionCases(remainingCities: [City]) {
    //     let ratedCities = remainingCities.filter { $0.rating != nil }
    //     
    //     // If we're down to fewer than 5 cities, we might want to adjust the rating system
    //     if ratedCities.count < 5 {
    //         print("Warning: Only \(ratedCities.count) rated cities remaining")
    //         
    //         // If only 1 city remains, ensure it has a 10.0 rating
    //         if ratedCities.count == 1 {
    //             ratedCities[0].rating = 10.0
    //         }
    //         
    //         // If 2-4 cities remain, spread them out more evenly
    //         if ratedCities.count >= 2 && ratedCities.count <= 4 {
    //             let sortedCities = ratedCities.sorted { ($0.rating ?? 0) < ($1.rating ?? 0) }
    //             let spacing = 9.0 / Double(sortedCities.count - 1) // From 1.0 to 10.0
    //             
    //             for (index, city) in sortedCities.enumerated() {
    //                 let newRating = 1.0 + (spacing * Double(index))
    //                 city.rating = min(10.0, max(1.0, newRating))
    //             }
    //         }
    //     }
    // }
}

//#Preview {
//    let preview = PreviewContainer([City.self])
//    let city = City(
//        name: "Vancouver",
//        latitude: 49.2827,
//        longitude: -123.1207,
//        bucketList: false,
//        isVisited: true,
//        country: "Canada",
//        admin: "British Columbia"
//    )
//    
//    NavigationStack {
//        CityDetailView(city: city)
//    }
//    .modelContainer(preview.container)
//}
