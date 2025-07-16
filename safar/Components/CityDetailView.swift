////
////  CityDetailView.swift
////  safar
////
////  Created by Assistant on 2025-07-11.
////
//
//import SwiftUI
//import MapKit
//
//struct CityDetailView: View {
//    @Environment(\.dismiss) private var dismiss
//    @Environment(\.modelContext) private var modelContext
//    
//    @State private var showingEditSheet = false
//    @State private var selectedPhoto: Photo?
//    @State private var showingPhotoDetail = false
//    
//    let city: City
//    
//    var restaurants: [Place] {
//        city.places.filter { $0.category == .restaurant }
//    }
//    
//    var hotels: [Place] {
//        city.places.filter { $0.category == .hotel }
//    }
//    
//    var activities: [Place] {
//        city.places.filter { $0.category == .activity }
//    }
//    
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 20) {
//                // Header
//                headerView
//                
//                // Photos
//                if !city.photos.isEmpty {
//                    photosSection
//                }
//                
//                // Rating and Notes
//                ratingNotesSection
//                
//                // Places
//                placesSection
//                
//                // Map
//                mapSection
//            }
//            .padding()
//        }
//        .navigationTitle(city.name)
//        .navigationBarTitleDisplayMode(.large)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button("Edit") {
//                    showingEditSheet = true
//                }
//            }
//        }
//        .sheet(isPresented: $showingEditSheet) {
//            EditCityView(city: city)
//        }
//        .sheet(isPresented: $showingPhotoDetail) {
//            if let photo = selectedPhoto {
//                PhotoDetailView(photo: photo)
//            }
//        }
//    }
//    
//    private var headerView: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                VStack(alignment: .leading) {
//                    Text(city.name)
//                        .font(.largeTitle)
//                        .fontWeight(.bold)
//                    
//                    Text("\(city.admin), \(city.country)")
//                        .font(.title2)
//                        .foregroundColor(.secondary)
//                }
//                
//                Spacer()
//                
//                VStack {
//                    Image(systemName: city.bucketList ? "list.clipboard.fill" : "checkmark.circle.fill")
//                        .font(.title)
//                        .foregroundColor(city.bucketList ? .orange : .green)
//                    
//                    Text(city.bucketList ? "Bucket List" : "Visited")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//            }
//        }
//    }
//    
//    private var photosSection: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("Photos")
//                .font(.headline)
//            
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 12) {
//                    ForEach(city.photos, id: \.id) { photo in
//                        Button(action: {
//                            selectedPhoto = photo
//                            showingPhotoDetail = true
//                        }) {
//                            if let image = photo.image {
//                                Image(uiImage: image)
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fill)
//                                    .frame(width: 120, height: 120)
//                                    .clipShape(RoundedRectangle(cornerRadius: 12))
//                            }
//                        }
//                    }
//                }
//                .padding(.horizontal)
//            }
//        }
//    }
//    
//    private var ratingNotesSection: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            // Rating
//            if let rating = city.rating {
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Rating")
//                        .font(.headline)
//                    
//                    HStack {
//                        ForEach(1...5, id: \.self) { star in
//                            Image(systemName: star <= rating ? "star.fill" : "star")
//                                .font(.title2)
//                                .foregroundColor(.yellow)
//                        }
//                        
//                        Text("(\(rating)/5)")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                }
//            }
//            
//            // Notes
//            if let notes = city.notes, !notes.isEmpty {
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Notes")
//                        .font(.headline)
//                    
//                    Text(notes)
//                        .font(.body)
//                        .padding()
//                        .background(Color.gray.opacity(0.1))
//                        .cornerRadius(8)
//                }
//            }
//        }
//    }
//    
//    private var placesSection: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            // Restaurants
//            if !restaurants.isEmpty {
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Restaurants")
//                        .font(.headline)
//                    
//                    ForEach(restaurants, id: \.id) { restaurant in
//                        PlaceCard(place: restaurant)
//                    }
//                }
//            }
//            
//            // Hotels
//            if !hotels.isEmpty {
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Hotels")
//                        .font(.headline)
//                    
//                    ForEach(hotels, id: \.id) { hotel in
//                        PlaceCard(place: hotel)
//                    }
//                }
//            }
//            
//            // Activities
//            if !activities.isEmpty {
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Activities")
//                        .font(.headline)
//                    
//                    ForEach(activities, id: \.id) { activity in
//                        PlaceCard(place: activity)
//                    }
//                }
//            }
//        }
//    }
//    
//    private var mapSection: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("Location")
//                .font(.headline)
//            
//            Map(coordinateRegion: .constant(MKCoordinateRegion(
//                center: city.coordinate,
//                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
//            )), annotationItems: [city]) { city in
//                MapMarker(coordinate: city.coordinate, tint: .red)
//            }
//            .frame(height: 200)
//            .cornerRadius(12)
//        }
//    }
//}
//
//struct PlaceCard: View {
//    let place: Place
//    
//    var body: some View {
//        HStack {
//            Image(systemName: iconForCategory(place.category))
//                .font(.title2)
//                .foregroundColor(colorForCategory(place.category))
//                .frame(width: 30)
//            
//            VStack(alignment: .leading, spacing: 2) {
//                Text(place.name)
//                    .font(.subheadline)
//                    .fontWeight(.medium)
//                
//                Text(place.category.rawValue.capitalized)
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//            
//            Spacer()
//            
//            Button(action: {
//                openInMaps(place: place)
//            }) {
//                Image(systemName: "arrow.up.right.square")
//                    .foregroundColor(.accentColor)
//            }
//        }
//        .padding()
//        .background(Color.gray.opacity(0.1))
//        .cornerRadius(8)
//    }
//    
//    private func iconForCategory(_ category: PlaceCategory) -> String {
//        switch category {
//        case .restaurant: return "fork.knife"
//        case .hotel: return "bed.double"
//        case .activity: return "figure.walk"
//        }
//    }
//    
//    private func colorForCategory(_ category: PlaceCategory) -> Color {
//        switch category {
//        case .restaurant: return .orange
//        case .hotel: return .blue
//        case .activity: return .green
//        }
//    }
//    
//    private func openInMaps(place: Place) {
//        let coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
//        let placemark = MKPlacemark(coordinate: coordinate)
//        let mapItem = MKMapItem(placemark: placemark)
//        mapItem.name = place.name
//        mapItem.openInMaps()
//    }
//}
//
//struct PhotoDetailView: View {
//    @Environment(\.dismiss) private var dismiss
//    let photo: Photo
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                if let image = photo.image {
//                    Image(uiImage: image)
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                }
//                
//                Spacer()
//                
//                Text("Added on \(photo.dateAdded.formatted(date: .abbreviated, time: .omitted))")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                    .padding()
//            }
//            .navigationTitle("Photo")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Done") {
//                        dismiss()
//                    }
//                }
//            }
//        }
//    }
//}
//
//struct EditCityView: View {
//    @Environment(\.dismiss) private var dismiss
//    @Environment(\.modelContext) private var modelContext
//    
//    @State private var notes: String
//    @State private var rating: Int?
//    
//    let city: City
//    
//    init(city: City) {
//        self.city = city
//        _notes = State(initialValue: city.notes ?? "")
//        _rating = State(initialValue: city.rating)
//    }
//    
//    var body: some View {
//        NavigationView {
//            Form {
//                Section("Rating") {
//                    HStack {
//                        Text("Rating")
//                        Spacer()
//                        
//                        HStack {
//                            ForEach(1...5, id: \.self) { star in
//                                Button(action: {
//                                    rating = star
//                                }) {
//                                    Image(systemName: star <= (rating ?? 0) ? "star.fill" : "star")
//                                        .foregroundColor(.yellow)
//                                }
//                            }
//                        }
//                    }
//                }
//                
//                Section("Notes") {
//                    TextEditor(text: $notes)
//                        .frame(minHeight: 100)
//                }
//            }
//            .navigationTitle("Edit \(city.name)")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") {
//                        dismiss()
//                    }
//                }
//                
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Save") {
//                        saveChanges()
//                    }
//                }
//            }
//        }
//    }
//    
//    private func saveChanges() {
//        city.notes = notes.isEmpty ? nil : notes
//        city.rating = rating
//        
//        do {
//            try modelContext.save()
//        } catch {
//            print("Failed to save changes: \(error)")
//        }
//        
//        dismiss()
//    }
//}
//
//#Preview {
//    let city = City(
//        name: "Vancouver",
//        latitude: 49.2827,
//        longitude: -123.1207,
//        bucketList: false,
//        isVisited: true,
//        country: "Canada",
//        admin: "British Columbia"
//    )
//    city.rating = 4
//    city.notes = "Amazing city with great food and beautiful mountains!"
//    
//    return NavigationView {
//        CityDetailView(city: city)
//    }
//}
