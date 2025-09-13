////
////  PlaceCategorySection.swift
////  safar
////
////  Created by Arman Kassam on 2025-07-17.
////
//
//import SwiftUI
//
//struct PlaceCategorySection: View {
//    let category: PlaceCategory
//    let places: [Place]
//    let onAddPlaces: () -> Void
//    let onRemovePlace: (Place) -> Void
//    let onPlaceSelected: (Place) -> Void
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                Image(systemName: category.icon)
//                    .foregroundColor(category.systemColor)
//                Text("\(category.pluralDisplayName) (\(places.count))")
//                    .font(.subheadline)
//                    .fontWeight(.medium)
//                Spacer()
//                
//                Button(action: onAddPlaces) {
//                    Image(systemName: "plus.circle.fill")
//                        .foregroundColor(.accentColor)
//                }
//            }
//            
//            if places.isEmpty {
//                Text("No \(category.pluralDisplayName.lowercased()) added yet")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                    .padding(.leading, 24)
//            } else {
//                ForEach(places, id: \.id) { place in
//                    HStack {
//                        Button(action: {
//                            onPlaceSelected(place)
//                        }) {
//                            HStack {
//                                Text(place.name)
//                                    .font(.subheadline)
//                                    .foregroundColor(.primary)
//                                Image(systemName: "location.fill")
//                                    .font(.caption)
//                                    .foregroundColor(.secondary)
//                            }
//                        }
//                        .buttonStyle(PlainButtonStyle())
//                        PlaceRatingSection(place: place)
//                        Spacer()
//                        
//                        Button(action: {
//                            onRemovePlace(place)
//                        }) {
//                            Image(systemName: "xmark")
//                                .foregroundColor(.red)
//                                .font(.caption)
//                        }
//                    }
//                    .padding(.leading, 4)
//                    .padding(.trailing, 4)
//                }
//            }
//        }
//        .padding(.vertical, 4)
//    }
//}
