//
//  YourCitiesView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-05.
//
import SwiftUI
import SwiftData

struct YourCitiesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<City> { $0.isVisited == true }) private var visitedCities: [City]
    @Query(filter: #Predicate<City> { $0.bucketList == true }) private var bucketListCities: [City]

    @State private var selectedTab: CityTab = .visited
    @State private var cityToDelete: City?
    @State private var showDeleteConfirmation = false

    enum CityTab: String, CaseIterable, Identifiable, IconRepresentable {
        case visited = "Visited"
        case bucketList = "Bucket List"
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .visited: return "suitcase.fill"
            case .bucketList: return "star.fill"
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
                        NavigationLink(destination: CityDetailView(city: city)) {
                            EmptyView()
                        }
                    }
                    .listRowBackground(Color("Background"))
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .background(Color("Background"))
            }
            .background(Color("Background"))
        }
    }

    private var currentCities: [City] {
        switch selectedTab {
        case .visited:
            return visitedCities
        case .bucketList:
            return bucketListCities
        }
    }
}
