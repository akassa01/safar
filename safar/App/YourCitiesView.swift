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
                CityListMember(index: i, city: city, bucketList: selectedTab.bucketList)
                    .listRowBackground(Color("Background"))
                    .listRowSeparator(.hidden)
                    .swipeActions {
                        Button(role: .destructive) {
                            cityToDelete = city
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            .listStyle(.plain)
            .background(Color("Background"))
        }
        .background(Color("Background"))
        .alert("Delete City?", isPresented: $showDeleteConfirmation, presenting: cityToDelete) { city in
            Button("Delete", role: .destructive) {
                delete(city)
            }
            Button("Cancel", role: .cancel) {}
        } message: { city in
            Text("Are you sure you want to remove \(city.name) from  \(selectedTab.rawValue)? This cannot be undone.")
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

    private func delete(_ city: City) {
        modelContext.delete(city)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting city: \(error)")
        }
    }
}


#Preview("Empty City List") {
    let preview = PreviewContainer([City.self])
    return YourCitiesView().modelContainer(preview.container)
}
//
//#Preview("City List w/ Items") {
//    let preview = PreviewContainer([City.self])
//    let items = [
//            City(name: "New York", latitude: 40.7128, longitude: -74.0060, bucketList: false, isVisited: true, country: "USA", admin: "New York"),
//            City(name: "Tokyo", latitude: 35.6895, longitude: 139.6917, bucketList: true, isVisited: false, country: "Japan", admin: "Tokyo"),
//            City(name: "Paris", latitude: 48.8566, longitude: 2.3522, bucketList: true, isVisited: false, country: "France", admin: "Île-de-France")
//        ]
//
//    preview.add(items: items)
//    return YourCitiesView().modelContainer(preview.container)
//}
