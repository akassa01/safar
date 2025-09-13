////
////  PlaceRatingSection.swift
////  safar
////
////  Created by Arman Kassam on 2025-07-17.
////
//import SwiftUI
//
//struct PlaceRatingSection: View {
//    var place: Place
//    var body: some View {
//        // Add rating display and edit buttons
//            if let liked = place.liked {
//                Image(systemName: liked ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
//                    .foregroundColor(.accent)
//                    .font(.caption)
//            }
//            
//            // Rating edit buttons
//        HStack(spacing: 4) {
//            Button(action: {
//                place.liked = place.liked == true ? nil : true
//            }) {
//                Image(systemName: "hand.thumbsup")
//                    .foregroundColor(place.liked == true ? .green : .gray)
//                    .font(.caption)
//            }
//            
//            Button(action: {
//                place.liked = place.liked == false ? nil : false
//            }) {
//                Image(systemName: "hand.thumbsdown")
//                    .foregroundColor(place.liked == false ? .red : .gray)
//                    .font(.caption)
//            }
//        }
//    }
//}
