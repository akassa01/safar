//
//  RankingSheet.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-09.
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddCityView: View {
    var baseResult: SearchResult
    var isVisited: Bool
    var onSave: (City) -> Void
    @Environment(\.modelContext) private var modelContext

    @Environment(\.dismiss) var dismiss

    // Basic fields
    @State private var cityName = ""
    @State private var country = ""
    @State private var rating: Double = 50

    // Optional details
    @State private var hotelResults: [Place] = []
    @State private var restaurantResults: [Place] = []
    @State private var activityResults: [Place] = []

    @State private var notes = ""

    // Images
//    @State private var selectedPhotos: [PhotosPickerItem] = []
//    @State private var images: [UIImage] = []

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ranking")) {
                    Text("\(Int(rating))")
                    Slider(value: $rating, in: 1...100, step: 1)
                }

                PlaceSearchSection(title: "Hotels", category: .hotel, results: $hotelResults)
                PlaceSearchSection(title: "Restaurants", category: .restaurant, results: $restaurantResults)
                PlaceSearchSection(title: "Activities", category: .activity, results: $activityResults)

                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }

//                Section(header: Text("Images")) {
//                    PhotosPicker(selection: $selectedPhotos,
//                                 maxSelectionCount: 5,
//                                 matching: .images,
//                                 photoLibrary: .shared()) {
//                        Label("Add Photos", systemImage: "photo")
//                    }
//
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        HStack {
//                            ForEach(images, id: \.self) { image in
//                                Image(uiImage: image)
//                                    .resizable()
//                                    .scaledToFill()
//                                    .frame(width: 100, height: 100)
//                                    .clipped()
//                                    .cornerRadius(10)
//                            }
//                        }
//                    }
//                }
               

            }
            .background(Color("Background"))
            .navigationTitle("\(baseResult.title), \(baseResult.country)")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCityToModel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
//            .onChange(of: selectedPhotos) { oldItems,newItems in
//                Task {
//                    images = []
//                    for item in newItems {
//                        if let data = try? await item.loadTransferable(type: Data.self),
//                           let image = UIImage(data: data) {
//                            images.append(image)
//                        }
//                    }
//                }
//            }
            
        }
    }
    private func saveCityToModel() {
        guard let long = baseResult.longitude, let lat = baseResult.latitude else {
            print("Invalid coordinates")
            return
        }

        let newCity = City(
            name: baseResult.title,
            latitude: lat,
            longitude: long,
            bucketList: !isVisited,
            isVisited: isVisited,
            country: baseResult.country,
            admin: baseResult.admin
        )

        newCity.rating = Int(rating)
        newCity.notes = notes
        let allPlaces = hotelResults + restaurantResults + activityResults
        for place in allPlaces {
            place.city = newCity
            modelContext.insert(place)
        }

        onSave(newCity)
        dismiss()
    }
}

//#Preview {
//    AddCityView()
//}
