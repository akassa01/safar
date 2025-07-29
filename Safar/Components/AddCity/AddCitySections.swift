//
//  AddCitySections.swift
//  Safar
//
//  Created by Arman Kassam on 2025-07-22.
//

import SwiftUI
import PhotosUI

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
