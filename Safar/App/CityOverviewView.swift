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
                        }
                        .padding(.bottom, 20)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color("Background"))
                .ignoresSafeArea(edges: .top)
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
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
        CityBannerView(
            cityId: city.id,
            cityName: city.displayName,
            admin: city.admin,
            country: city.country,
            population: city.population,
            rating: nil,
            isVisited: nil,
            showActionButtons: true
        )
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
}
#Preview {
    NavigationStack {
        CityOverviewView(cityId: 1)
    }
}
