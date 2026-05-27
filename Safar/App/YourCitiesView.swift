//
//  YourCitiesView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-05.
//
import SwiftUI

struct YourCitiesView: View {
    @EnvironmentObject var viewModel: UserCitiesViewModel
    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    @State private var selectedTab: CityTab = .visited
    @State private var cityToDelete: City?
    @State private var showDeleteConfirmation = false
    @State private var cityToMarkVisited: City?
    @State private var showOfflineToast = false
    @State private var friendCounts: [Int: Int] = [:]

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
        VStack {
                TabBarView<CityTab>(
                    selectedCategory: $selectedTab,
                    iconSize: 22,
                )

                List(currentCities.sorted(by: { $0.displayName < $1.displayName }), id: \.self) { city in
                    ZStack {
                        CityListMember(
                            city: city,
                            bucketList: selectedTab.bucketList,
                            friendCount: selectedTab == .bucketList ? friendCounts[city.id] : nil
                        )
                        NavigationLink(destination: CityDetailView(cityId: city.id)) {
                            EmptyView()
                        }
                        .opacity(0)
                    }
                    .contentShape(Rectangle())
                    .contextMenu {
                        if networkMonitor.isConnected {
                            if selectedTab == .visited {
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
                    }
                    .listRowBackground(Color("Background"))
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .background(Color("Background"))
                .toast(isPresented: $showOfflineToast, message: "City details unavailable offline")
                .task {
                    if selectedTab == .bucketList {
                        await loadFriendCounts()
                    }
                }
                .onChange(of: selectedTab) { _, newTab in
                    if newTab == .bucketList {
                        Task { await loadFriendCounts() }
                    }
                }
                .onChange(of: viewModel.bucketListCities) { _, _ in
                    if selectedTab == .bucketList {
                        Task { await loadFriendCounts() }
                    }
                }
            }
            .background(Color("Background"))
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
            .navigationTitle("Your Cities")
            .navigationBarTitleDisplayMode(.inline)
    }

    private var currentCities: [City] {
        switch selectedTab {
        case .visited:
            return viewModel.visitedCities
        case .bucketList:
            return viewModel.bucketListCities
        }
    }

    private func loadFriendCounts() async {
        let cities = viewModel.bucketListCities
        guard !cities.isEmpty, let userId = viewModel.currentUserId else { return }
        for city in cities {
            let count = (try? await DatabaseManager.shared.getFriendVisitCount(cityId: city.id, userId: userId)) ?? 0
            friendCounts[city.id] = count
        }
    }
}
