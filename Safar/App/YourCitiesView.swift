//
//  YourCitiesView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-05.
//
import SwiftUI

struct YourCitiesView: View {
    @EnvironmentObject var viewModel: UserCitiesViewModel

    @State private var selectedTab: CityTab = .visited
    @State private var cityToDelete: City?
    @State private var showDeleteConfirmation = false
    @State private var showingRatingSheet = false
    @State private var cityToRate: City?
    @State private var cityToMarkVisited: City?

    enum CityTab: String, CaseIterable, Identifiable, IconRepresentable {
        case visited = "Visited"
        case bucketList = "Bucket List"
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .visited: return "suitcase.fill"
            case .bucketList: return "bookmark.fill"
            }
        }
        var bucketList: Bool {
            switch self {
            case .visited: return false
            case .bucketList: return true
            }
        }
        
    }

    var body: some View {
        NavigationStack {
            VStack {
                Spacer(minLength: 24)
                Text("Your Cities")
                    .font(.title)
                    .bold()
                
                TabBarView<CityTab>(
                    selectedCategory: $selectedTab,
                    iconSize: 22,
                )

                List(currentCities.sorted(by: { $0.rating ?? 0 > $1.rating ?? 0 }).enumerated().map({ $0 }), id: \.element) { i, city in
                    ZStack {
                        CityListMember(index: i, city: city, bucketList: selectedTab.bucketList, locked: currentCities.count < 5)
                        NavigationLink(destination: CityDetailView(cityId: city.id)) {
                            EmptyView()
                        }
                        .opacity(0)
                    }
                    .contextMenu {
                        if selectedTab == .visited {
                            Button {
                                cityToRate = city
                                showingRatingSheet = true
                            } label: {
                                Label("Change Rating", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                cityToDelete = city
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } else {
                            Button {
                                cityToMarkVisited = city
                            } label: {
                                Label("Mark as Visited", systemImage: "checkmark.circle")
                            }
                            Button(role: .destructive) {
                                cityToDelete = city
                                showDeleteConfirmation = true
                            } label: {
                                Label("Remove from Bucket List", systemImage: "bookmark.slash")
                            }
                        }
                    }
                    .listRowBackground(Color("Background"))
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .background(Color("Background"))
            }
            .background(Color("Background"))
            .sheet(isPresented: $showingRatingSheet) {
                if let city = cityToRate {
                    CityRatingView(
                        isPresented: $showingRatingSheet,
                        cityName: city.displayName,
                        country: city.country,
                        cityID: city.id,
                        onRatingSelected: { rating in
                            Task {
                                await viewModel.updateCityRating(cityId: city.id, rating: rating)
                            }
                        }
                    )
                    .presentationBackground(Color("Background"))
                }
            }
            .sheet(item: $cityToMarkVisited) { city in
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
                    isVisited: true,
                    onSave: { _ in
                        Task {
                            await viewModel.loadUserData()
                        }
                    }
                )
                .environmentObject(viewModel)
            }
            .alert("Remove City", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    cityToDelete = nil
                }
                Button("Remove", role: .destructive) {
                    if let city = cityToDelete {
                        Task {
                            await viewModel.removeCityFromList(cityId: city.id)
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to remove \(cityToDelete?.displayName ?? "this city")? This action cannot be undone.")
            }
        }
    }

    private var currentCities: [City] {
        switch selectedTab {
        case .visited:
            return viewModel.visitedCities
        case .bucketList:
            return viewModel.bucketListCities
        }
    }
}
