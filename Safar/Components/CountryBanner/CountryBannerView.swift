//
//  CountryBannerView.swift
//  Safar
//

import SwiftUI

struct CountryBannerView: View {
    let countryId: Int64
    let countryName: String
    let rating: Double
    let rank: Int?

    @StateObject private var photoViewModel = CountryPhotoViewModel()
    @State private var showingAttribution = false

    private var bannerHeight: CGFloat { UIScreen.main.bounds.height * 0.4 }

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundLayer

            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Content overlay
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(countryName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

                Spacer()

                if rating > 0 {
                    RatingCircle(rating: rating, size: 50)
                }
            }
            .padding()

            // Attribution info button (top right)
            if photoViewModel.countryPhoto != nil {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            showingAttribution = true
                        } label: {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(8)
                        }
                    }
                    Spacer()
                }
            }
        }
        .frame(height: bannerHeight)
	.clipped()
        .task {
            await photoViewModel.loadPhoto(for: Int(countryId), countryName: countryName)
        }
        .sheet(isPresented: $showingAttribution) {
            if let photo = photoViewModel.countryPhoto {
                PhotoAttributionSheet(photo: photo)
                    .presentationDetents([.height(250)])
            }
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if let photo = photoViewModel.countryPhoto,
           let url = URL(string: photo.photoURLRegular) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholderGradient
                        .overlay(ProgressView().tint(.white))
                case .success(let image):
                    Color.clear
                        .frame(height: bannerHeight)
                        .overlay(
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        )
                        .clipped()
                case .failure:
                    placeholderGradient
                @unknown default:
                    placeholderGradient
                }
            }
        } else if photoViewModel.isLoading {
            placeholderGradient
                .overlay(ProgressView().tint(.white))
        } else {
            placeholderGradient
        }
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    CountryBannerView(
        countryId: 1,
        countryName: "Japan",
        rating: 8.9,
        rank: 1
    )
}
