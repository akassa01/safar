//
//  SearchMainView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-02.
//

import SwiftUI
import MapKit
import SwiftData

struct SearchResult: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let latitude: Double?
    let longitude: Double?
    let population: Int
    let country: String
    let admin: String
}
enum SearchCategory: String, CaseIterable, Hashable, IconRepresentable {
    case cities = "Cities"
    case countries = "Countries"
    case places = "Places"
    case people = "People"

    var icon: String {
        switch self {
        case .cities: return "building.2"
        case .countries: return "globe"
        case .places: return "mappin"
        case .people: return "person.2"
        }
    }
}

struct SearchMainView: View {
    @Query var cities: [City]
    @FocusState private var isSearchFieldFocused: Bool
    @State private var searchText: String = ""
    @State private var selectedCategory: SearchCategory = .cities
    @Environment(\.dismiss) var dismiss

    @State private var isLoading = false
    @State private var searchResults = [SearchResult]()
    @State private var debounceTask: DispatchWorkItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // search bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.accent)
                        TextField("Search for \(selectedCategory.rawValue)", text: $searchText)
                            .focused($isSearchFieldFocused)
                            .onChange(of: searchText) {
                                performSearch()
                            }
                            .textInputAutocapitalization(.none)
                            .autocorrectionDisabled()
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.systemGray4))
                    .cornerRadius(10)

                    Button("Cancel") {
                        isSearchFieldFocused = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            dismiss()
                        }
                    }
                    .foregroundColor(.accentColor)
                }
                .padding()
                .background(Color("Background"))

                TabBarView<SearchCategory>(
                    selectedCategory: $selectedCategory,
                    iconSize: 20,
                )

                if isLoading {
                    ProgressView()
                        .padding()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Text("No results found")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List(searchResults.sorted(by: { $0.population > $1.population })) { result in
                        
                        let matchingCities = cities.filter {
                                $0.latitude == result.latitude && $0.longitude == result.longitude
                            }
                        
                        let searchedCity: City = matchingCities.first ?? City(name: result.title, latitude: result.latitude ?? 0, longitude: result.longitude ?? 0, bucketList: false, isVisited: false, country: result.country, admin: result.admin)
                        
                        ZStack {
                            SearchListMember(result: result)
                                .listRowBackground(Color("Background"))
                            NavigationLink(destination: CityDetailView(city: searchedCity)) {
                                EmptyView()
                            }
                        }
                        .listRowBackground(Color("Background"))

                        
                    }
                    .listStyle(.plain)
                    .background(Color("Background"))
                }

                Spacer()
            }
            .background(Color("Background"))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isSearchFieldFocused = true
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func performSearch() {
        debounceTask?.cancel()
        
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }

        let task = DispatchWorkItem {
            isLoading = true
            DispatchQueue.main.async {
                    self.executeSearch()
            }
        }

        debounceTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: task)
    }
    private func executeSearch() {
        let currentQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        switch selectedCategory {
        case .cities:
            DispatchQueue.global(qos: .userInitiated).async {
                let results = DatabaseManager.shared.searchCities(query: currentQuery)
                DispatchQueue.main.async {
                    self.searchResults = results
                    self.isLoading = false
                }
            }

        case .countries:
            DispatchQueue.global(qos: .userInitiated).async {
                let results = DatabaseManager.shared.searchCountries(query: currentQuery)
                    .map { SearchResult(title: $0, subtitle: "", latitude: nil, longitude: nil, population: 0, country: "", admin: "") }
                DispatchQueue.main.async {
                    self.searchResults = results
                    self.isLoading = false
                }
            }

        case .places:
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            request.resultTypes = .pointOfInterest

            let search = MKLocalSearch(request: request)
            search.start { response, error in
                isLoading = false
                if let items = response?.mapItems {
                    self.searchResults = items.map {
                        SearchResult(title: $0.name ?? "Unknown", subtitle: $0.placemark.title ?? "", latitude: nil, longitude: nil, population: 0, country: "", admin: "")
                    }
                }
            }

        case .people:
            searchResults = []
            isLoading = false
        }
    }
}

extension MKMapItem: @retroactive Identifiable {
    public var id: String {
        return self.placemark.description
    }

    var name: String? {
        return self.placemark.name ?? self.placemark.locality ?? self.placemark.country
    }
}



#Preview {
    SearchMainView()
}
