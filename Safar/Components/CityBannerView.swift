//
//  CityBannerView.swift
//  Safar
//

import SwiftUI

struct CityBannerView: View {
    let cityId: Int
    let cityName: String
    let admin: String
    let country: String
    let population: Int
    let rating: Double?
    let communityRating: Double?
    let communityRatingCount: Int?
    let isVisited: Bool?  // nil = not added, true = visited, false = bucket list
    let showActionButtons: Bool

    // Action callbacks
    var onAddToVisited: (() -> Void)?
    var onAddToBucketList: (() -> Void)?
    var onRemoveFromBucketList: (() -> Void)?

    @StateObject private var photoViewModel = CityPhotoViewModel()
    @State private var showingAttribution = false

    private static let populationThreshold = 125_000
    private var bannerHeight: CGFloat { UIScreen.main.bounds.height * 0.4 }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background photo or gradient fallback
            backgroundLayer

            // Gradient overlay for text readability
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Content overlay
            HStack(alignment: .bottom) {
                // Left side: City name and location
                VStack(alignment: .leading, spacing: 4) {
                    Text(cityName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("\(admin), \(country)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                // Right side: Rating or action buttons
                rightContent
            }
            .padding()

            // Attribution info button (top right)
            if photoViewModel.cityPhoto != nil {
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
            guard population > Self.populationThreshold else { return }
            await photoViewModel.loadPhoto(
                for: cityId,
                cityName: cityName,
                country: country
            )
        }
        .sheet(isPresented: $showingAttribution) {
            if let photo = photoViewModel.cityPhoto {
                PhotoAttributionSheet(photo: photo)
                    .presentationDetents([.height(250)])
            }
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if let photo = photoViewModel.cityPhoto,
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

    @ViewBuilder
    private var rightContent: some View {
        let buttonSize: CGFloat = 25.0;
        if isVisited == true {
            // Visited: show personal rating and/or community rating
            HStack(spacing: 8) {
                if let rating = rating {
                    RatingCircle(rating: rating, size: 50)
                }
                if let communityRating = communityRating {
                    CommunityRatingCircle(rating: communityRating, ratingCount: communityRatingCount, size: 50)
                }
            }
        } else {
            // Not visited: show community rating if available
            if let communityRating = communityRating {
                CommunityRatingCircle(rating: communityRating, ratingCount: communityRatingCount, size: 50)
            }
        }

        if isVisited == false && showActionButtons {
            // Bucket list: show mark visited + remove buttons
            HStack(spacing: 10) {
                Button {
                    onAddToVisited?()
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.accent)
                        .font(.system(size: buttonSize))
                }
                .buttonStyle(BorderlessButtonStyle())

                Button {
                    onRemoveFromBucketList?()
                } label: {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(.accent)
                        .font(.system(size: buttonSize))
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        } else if isVisited == nil && showActionButtons {
            // Not added: show add to visited + bucket list buttons
            HStack(spacing: 10) {
                Button {
                    onAddToVisited?()
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.accent)
                        .font(.system(size: buttonSize))
                }
                .buttonStyle(BorderlessButtonStyle())

                Button {
                    onAddToBucketList?()
                } label: {
                    Image(systemName: "bookmark")
                        .foregroundColor(.accent)
                        .font(.system(size: buttonSize))
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
}

// MARK: - Photo Attribution Sheet

struct PhotoAttributionSheet: View {
    let photo: any PhotoAttributable
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Attribution info
                // Photographer
                if let photographerURL = photo.photographerURL {
                    Link(destination: photographerURL) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading) {
                                Text("Photo by")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(photo.photographerName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }

                // View on Unsplash
                if let unsplashURL = photo.photoPageURL {
                    Link(destination: unsplashURL) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading) {
                                Text("View on")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Unsplash")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                
                // Unsplash attribution text
                Text("Photos provided by Unsplash")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Photo Credit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    VStack {
        CityBannerView(
            cityId: 1,
            cityName: "Paris",
            admin: "Île-de-France",
            country: "France",
            population: 2_161_000,
            rating: 8.5,
            communityRating: 7.2,
            communityRatingCount: 42,
            isVisited: true,
            showActionButtons: false
        )

        CityBannerView(
            cityId: 2,
            cityName: "Tokyo",
            admin: "Tokyo",
            country: "Japan",
            population: 13_960_000,
            rating: nil,
            communityRating: 8.1,
            communityRatingCount: 42,
            isVisited: nil,
            showActionButtons: true
        )
    }
}
