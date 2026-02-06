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
    let isVisited: Bool?  // nil = not added, true = visited, false = bucket list
    let showActionButtons: Bool

    // Action callbacks
    var onAddToVisited: (() -> Void)?
    var onAddToBucketList: (() -> Void)?

    @StateObject private var photoViewModel = CityPhotoViewModel()
    @State private var showingAttribution = false

    private static let populationThreshold = 125_000
    private var bannerHeight: CGFloat { UIScreen.main.bounds.height * 0.25 }

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
                    .presentationDetents([.medium])
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
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
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
        if isVisited == true {
            // Visited: show rating if available
            if let rating = rating {
                EnhancedRatingDisplay(rating: rating)
            }
        } else if isVisited == false {
            // Bucket list: show status badge
            EnhancedStatusBadge(
                icon: "bookmark.fill",
                text: "Bucket List",
                color: .accentColor
            )
        } else if showActionButtons {
            // Not added: show action buttons
            VStack(spacing: 8) {
                Button(action: { onAddToVisited?() }) {
                    Label("Visited", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .cornerRadius(16)
                }

                Button(action: { onAddToBucketList?() }) {
                    Label("Bucket List", systemImage: "bookmark.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(16)
                }
            }
        }
    }
}

// MARK: - Photo Attribution Sheet

struct PhotoAttributionSheet: View {
    let photo: CityPhoto
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Photo preview
                if let url = URL(string: photo.photoURLSmall) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 150)
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 150)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                // Attribution info
                VStack(spacing: 16) {
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
                }

                Spacer()

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
            isVisited: nil,
            showActionButtons: true
        )
    }
}
