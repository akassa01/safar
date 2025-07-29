//
//  PlaceRowInList.swift
//  Safar
//
//  Created by Arman Kassam on 2025-07-22.
//

import SwiftUI

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
