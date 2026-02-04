//
//  CityOverviewView.swift
//  Safar
//
//  Community-focused city view showing community ratings, friends who visited,
//  and the current user's status with the city.
//

import SwiftUI

struct CityOverviewView: View {
    @EnvironmentObject var userCitiesViewModel: UserCitiesViewModel
    @StateObject private var viewModel = CityOverviewViewModel()
    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    let cityId: Int

    @State private var showingAddCityView = false
    @State private var addAsVisited = true

    private var isOffline: Bool { !networkMonitor.isConnected }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading city...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("Background"))
            } else if let city = viewModel.city {
                ScrollView {
                    VStack(spacing: 0) {
                        if isOffline {
                            OfflineBannerView(lastSyncDate: CityCacheManager.shared.lastSyncDate)
                        }

                        VStack(spacing: 20) {
                            headerSection(city: city)
                            communityRatingSection(city: city)
                            friendsSection(city: city)
                            userStatusSection(city: city)
                        }
                        .padding(.bottom, 20)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color("Background"))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("City not found")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    if let error = viewModel.error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("Background"))
            }
        }
        .navigationTitle(viewModel.city?.displayName ?? "City")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("Background"))
        .background(Color("Background"))
        .task {
            await viewModel.loadData(cityId: cityId)
        }
        .sheet(isPresented: $showingAddCityView) {
            if let city = viewModel.city {
                AddCityView(
                    baseResult: SearchResult(
                        title: city.displayName,
                        subtitle: "\(city.admin), \(city.country)",
                        latitude: city.latitude,
                        longitude: city.longitude,
                        population: city.population,
                        country: city.country,
                        admin: city.admin,
                        data_id: String(city.id)
                    ),
                    isVisited: addAsVisited,
                    onSave: { _ in
                        Task {
                            await userCitiesViewModel.loadUserData()
                            await viewModel.refreshUserStatus(cityId: cityId)
                        }
                    }
                )
                .environmentObject(userCitiesViewModel)
            }
        }
    }

    // MARK: - Header Section
    @ViewBuilder
    private func headerSection(city: City) -> some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 20)

            Text(city.displayName)
                .font(.title)
                .bold()
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Rectangle().fill(Color.accent))
                .cornerRadius(20)

            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.white.opacity(0.9))
                Text("\(city.admin), \(city.country)")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.2))
            .cornerRadius(20)
        }
    }

    // MARK: - Community Rating Section
    @ViewBuilder
    private func communityRatingSection(city: City) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Community Rating", icon: "person.3.fill")

            if let avgRating = city.averageRating,
               let ratingCount = city.ratingCount,
               ratingCount >= 5 {
                HStack {
                    Spacer()
                    CommunityRatingBadge(
                        averageRating: avgRating,
                        ratingCount: ratingCount
                    )
                    Spacer()
                }
            } else {
                let currentCount = city.ratingCount ?? 0
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.title2)
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Not enough ratings yet (\(currentCount)/5)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 12)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color("Background"))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Friends Who Visited Section
    @ViewBuilder
    private func friendsSection(city: City) -> some View {
        FriendsWhoVisitedSection(
            friends: viewModel.friendsWhoVisited,
            city: city
        )
        .padding(.horizontal)
    }

    // MARK: - User Status Section
    @ViewBuilder
    private func userStatusSection(city: City) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your Status", icon: "person.fill")

            switch viewModel.userStatus {
            case .visited(let rating, _):
                visitedStatusView(rating: rating)
            case .bucketList:
                bucketListStatusView
            case .notAdded:
                notAddedStatusView
            }
        }
        .padding()
        .background(Color("Background"))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func visitedStatusView(rating: Double?) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accent)
                Text("Visited")
                    .font(.headline)
                    .foregroundColor(.primary)

                if let rating = rating {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", rating))
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                } else {
                    Spacer()
                }
            }

            NavigationLink(destination: CityDetailView(cityId: cityId)) {
                Label("View My City Details", systemImage: "arrow.right.circle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accent)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }

    private var bucketListStatusView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(.accent)
                Text("On Bucket List")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            if !isOffline {
                Button {
                    addAsVisited = true
                    showingAddCityView = true
                } label: {
                    Label("Mark as Visited", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accent)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }

    private var notAddedStatusView: some View {
        VStack(spacing: 12) {
            if !isOffline {
                Button {
                    addAsVisited = true
                    showingAddCityView = true
                } label: {
                    Label("Add to Visited", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accent)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button {
                    Task {
                        await userCitiesViewModel.addCityToBucketList(cityId: cityId)
                        await viewModel.refreshUserStatus(cityId: cityId)
                    }
                } label: {
                    Label("Add to Bucket List", systemImage: "bookmark.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accent)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                Text("Actions unavailable offline")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CityOverviewView(cityId: 1)
    }
}
