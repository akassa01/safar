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
    @EnvironmentObject var viewModel: UserCitiesViewModel
    @StateObject private var placesViewModel = CityPlacesViewModel()
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @Environment(\.dismiss) private var dismiss

    let cityId: Int
    let isReadOnly: Bool
    let initialCity: City?
    let externalUserId: String?

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
    @State private var friendsWhoVisited: [FriendCityVisit] = []
    @State private var friendsSectionExpanded = true

    private var isOffline: Bool { !networkMonitor.isConnected }

    init(cityId: Int, isReadOnly: Bool = false, city: City? = nil, externalUserId: String? = nil) {
        self.cityId = cityId
        self.isReadOnly = isReadOnly
        self.initialCity = city
        self.externalUserId = externalUserId
        self._mapCameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: city?.latitude ?? 0, longitude: city?.longitude ?? 0),
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
                    VStack(spacing: 0) {
                        if isOffline {
                            OfflineBannerView(lastSyncDate: CityCacheManager.shared.lastSyncDate)
                        }

                        VStack {
                            headerSection

                            friendsSection(city: city)

                            if city.visited == true {
                                visitedCityContent
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color("Background"))
                .ignoresSafeArea(edges: .top)
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
            if let city = city, !isOffline, !isReadOnly {
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
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
                    onSave: { savedCity in
                        Task {
                            await loadCityData()
                        }
                    }
                )
                .environmentObject(viewModel)
            }
        }
        .sheet(isPresented: $showingNotesEditor, onDismiss: {
            Task {
                await loadCityData(showLoading: false)
            }
        }) {
            if let city = city {
                NotesEditorView(city: city)
                    .environmentObject(viewModel)
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
                            await loadCityData(showLoading: false)
                            print("Successfully updated city \(city.displayName), \(city.country)'s rating to \(rating) (unique ID: \(city.id))")
                        }
                    }
                )
                .environmentObject(viewModel)
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
        .sheet(item: $activePlaceCategory) { category in
            if let city = city {
                PlaceSearchView(
                    cityCoordinate: CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude),
                    category: category,
                    onPlacesSelected: { places in
                        Task {
                            await placesViewModel.addPlaces(places, to: city.id)
                            activePlaceCategory = nil
                        }
                    }
                )
            }
        }
        .alert("Delete City", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteCity()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(city?.displayName ?? "this city")? This action cannot be undone.")
        }
        .background(Color("Background"))
        .task {
            if isReadOnly, let initialCity = initialCity {
                // For read-only mode, use the provided city directly
                self.city = initialCity
                self.mapCameraPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: initialCity.latitude, longitude: initialCity.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
                // Load places for external user
                if let externalUserId = externalUserId, let uuid = UUID(uuidString: externalUserId) {
                    placesViewModel.setUserId(uuid)
                    await placesViewModel.loadPlaces(for: cityId)
                }
                self.isLoading = false
            } else {
                await loadCityData()
            }
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        if let city = city {
            VStack(spacing: 0) {
                // City banner with photo background
                CityBannerView(
                    cityId: city.id,
                    cityName: city.displayName,
                    admin: city.admin,
                    country: city.country,
                    population: city.population,
                    rating: viewModel.visitedCities.count >= 5 ? city.rating : nil,
                    communityRating: (city.ratingCount ?? 0) > 0 ? city.averageRating : nil,
                    isVisited: city.visited,
                    showActionButtons: !isReadOnly && !isOffline,
                    onAddToVisited: { showingAddCityView = true },
                    onAddToBucketList: { addToBucketList() },
                    onRemoveFromBucketList: { removeFromBucketList() }
                )
            }
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func friendsSection(city: City) -> some View {
        if !friendsWhoVisited.isEmpty || !isReadOnly {
            DisclosureGroup(isExpanded: $friendsSectionExpanded) {
                FriendsWhoVisitedContent(
                    friends: friendsWhoVisited,
                    city: city
                )
            } label: {
                SectionHeader(title: "Friends Who Visited", icon: "person.2.fill")
                    .foregroundColor(.primary)
            }
            .tint(.secondary)
            .padding()
            .background(Color("Background"))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 12)
        }
    }

    private var visitedCityContent: some View {
        VStack(spacing: 20) {
            mapSection
            placesSection
            notesSection
            // photosSection (optional)
        }
        .padding()
    }
    
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "City Map", icon: "map.fill")
            if let city = city {
                Map(position: $mapCameraPosition, selection: $selectedPlace) {

                    // Place markers (flattened from categories) as circles
                    let allPlaces = PlaceCategory.allCases.flatMap { category in
                        placesViewModel.placesByCategory[category] ?? []
                    }
                    ForEach(allPlaces, id: \.localKey) { place in
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
                .frame(height: 220)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                
                // Map controls
                HStack {
                    Button(action: {
                        withAnimation {
                            mapCameraPosition = .region(MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude),
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
            }
        }
        .padding()
        .background(Color("Background"))
        .cornerRadius(12)
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
    
    private var placesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader(title: "Places", icon: "mappin.and.ellipse")
                Spacer()
            }
            ForEach(PlaceCategory.allCases, id: \.self) { category in
                let categoryPlaces = placesViewModel.placesByCategory[category] ?? []
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(category.systemColor)
                        Text("\(category.pluralDisplayName) (\(categoryPlaces.count))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        if !isOffline && !isReadOnly {
                            Button {
                                activePlaceCategory = category
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    if categoryPlaces.isEmpty {
                        Text("No \(category.pluralDisplayName.lowercased()) added yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 24)
                    } else {
                        ForEach(categoryPlaces, id: \.localKey) { place in
                            HStack {
                                Text(place.name)
                                    .font(.subheadline)
                                Spacer()
                                if !isOffline && !isReadOnly {
                                    HStack(spacing: 8) {
                                        Button {
                                            Task { await placesViewModel.updateLiked(for: place.id ?? 0, liked: place.liked == true ? nil : true, cityId: cityId) }
                                        } label: {
                                            Image(systemName: place.liked == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                                                .foregroundColor(place.liked == true ? .green : .gray)
                                        }
                                        Button {
                                            Task { await placesViewModel.updateLiked(for: place.id ?? 0, liked: place.liked == false ? nil : false, cityId: cityId) }
                                        } label: {
                                            Image(systemName: place.liked == false ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                                .foregroundColor(place.liked == false ? .red : .gray)
                                        }
                                        Button(role: .destructive) {
                                            Task { await placesViewModel.deletePlace(placeId: place.id ?? 0, cityId: cityId) }
                                        } label: {
                                            Image(systemName: "xmark")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color("Background"))
        .cornerRadius(12)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Notes", icon: "note.text")
                Spacer()
                if !isOffline && !isReadOnly {
                    Button((city?.notes?.isEmpty ?? true) ? "Add Notes" : "Edit Notes") {
                        showingNotesEditor = true
                    }
                    .foregroundColor(.accentColor)
                }
            }

            if let city = city, let notes = city.notes, !notes.isEmpty {
                Text(notes)
                    .padding()
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                    .onTapGesture {
                        if !isReadOnly {
                            showingNotesEditor = true
                        }
                    }
            } else if !isOffline && !isReadOnly {
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
            } else {
                Text("No notes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(Color("Background"))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Functions

    private func openInAppleMaps(place: Place) {
        let encodedName = place.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(encodedName)&ll=\(place.latitude),\(place.longitude)") {
            UIApplication.shared.open(url)
        }
    }

    private func loadCityData(showLoading: Bool = true) async {
        if showLoading {
            isLoading = true
        }
        errorMessage = nil

        if viewModel.currentUserId == nil {
            await viewModel.initializeWithCurrentUser()
        }
        let loadedCity = await viewModel.getCityById(cityId: cityId)
        if let userId = viewModel.currentUserId {
            placesViewModel.setUserId(userId)
            await placesViewModel.loadPlaces(for: cityId)
            // Load friends who visited
            if let currentUserId = DatabaseManager.shared.getCurrentUserId() {
                if let friends = try? await DatabaseManager.shared.getFriendsWhoVisitedCity(cityId: cityId, userId: currentUserId) {
                    self.friendsWhoVisited = friends
                }
            }
        }
        
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
            await loadCityData(showLoading: false)
        }
    }

    private func removeFromBucketList() {
        Task {
            await viewModel.removeCityFromList(cityId: cityId)
            await loadCityData(showLoading: false)
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
            // Reload data and adjust ratings for remaining cities if needed
            await viewModel.loadUserData()
            let remainingRatedCities = viewModel.visitedCities.filter { ($0.rating ?? 0) > 0 }
            if let userId = viewModel.currentUserId, !remainingRatedCities.isEmpty {
                let newRatings = computeAdjustedRatings(remainingCities: remainingRatedCities)
                for (cityId, newRating) in newRatings {
                    do {
                        try await DatabaseManager.shared.updateUserCityRating(userId: userId, cityId: cityId, rating: newRating)
                    } catch {
                        print("Failed to update adjusted rating for city id \(cityId): \(error)")
                    }
                }
                await viewModel.loadUserData()
            }
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
    private func computeAdjustedRatings(remainingCities: [City]) -> [Int: Double] {
        guard !remainingCities.isEmpty else { return [:] }
        // Work on rated cities only
        let rated = remainingCities.compactMap { city -> (Int, Double)? in
            if let rating = city.rating { return (city.id, rating) }
            return nil
        }
        guard !rated.isEmpty else { return [:] }
        let count = rated.count
        var adjusted: [Int: Double] = [:]
        
        if count == 1 {
            adjusted[rated[0].0] = 10.0
            return adjusted
        }
        if count >= 2 && count <= 4 {
            let sorted = rated.sorted { $0.1 < $1.1 }
            let spacing = 9.0 / Double(count - 1)
            for (index, item) in sorted.enumerated() {
                let newRating = min(10.0, max(1.0, 1.0 + spacing * Double(index)))
                adjusted[item.0] = newRating
            }
            return adjusted
        }
        // count >= 5 → scale so max becomes 10
        if let maxRating = rated.map({ $0.1 }).max(), maxRating > 0, maxRating < 10.0 {
            let factor = 10.0 / maxRating
            for (id, rating) in rated {
                adjusted[id] = min(10.0, rating * factor)
            }
        } else {
            // Already at or above 10; clamp to 10
            for (id, rating) in rated {
                adjusted[id] = min(10.0, rating)
            }
        }
        return adjusted
    }

    // Legacy comment retained, logic folded into computeAdjustedRatings


    // Special cases handled inside computeAdjustedRatings
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
