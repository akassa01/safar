////
////  PlaceRowView.swift
////  safar
////
////  Created by Arman Kassam on 2025-07-17.
////

import SwiftUI
import MapKit

struct PlaceRowView: View {
    let mapItem: MKMapItem
    let category: PlaceCategory
    let isSelected: Bool
    let rating: Bool?
    let onTap: () -> Void
    let onRatingChanged: (Bool?) -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading) {
                    Image(systemName: category.icon)
                        .foregroundColor(category.systemColor)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mapItem.name ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let address = mapItem.placemark.formattedAddress {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                if isSelected {
                    HStack(spacing: 8) {
                        Button(action: {
                            onRatingChanged(rating == true ? nil : true)
                        }) {
                            Image(systemName: "hand.thumbsup.fill")
                                .foregroundColor(rating == true ? .green : .gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            onRatingChanged(rating == false ? nil : false)
                        }) {
                            Image(systemName: "hand.thumbsdown.fill")
                                .foregroundColor(rating == false ? .red : .gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.title2)
            }
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
