//
//  SearchMainView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-02.
//

import SwiftUI
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
    let data_id: String
}

enum SearchResultItem: Identifiable {
    case city(SearchResult)
    case person(ProfileSearchResult)

    var id: String {
        switch self {
        case .city(let result): return result.id.uuidString
        case .person(let result): return result.id
        }
    }
}
enum SearchCategory: String, CaseIterable, Hashable, IconRepresentable {
    case cities = "Cities"
    case countries = "Countries"
    case people = "People"

    var icon: String {
        switch self {
        case .cities: return "building.2"
        case .countries: return "globe"
        case .people: return "person.2"
        }
    }
}

struct SearchMainView: View {
    @EnvironmentObject var viewModel: UserCitiesViewModel
    @FocusState private var isSearchFieldFocused: Bool
    @State private var searchText: String = ""
    @State private var selectedCategory: SearchCategory = .cities
    @Environment(\.dismiss) var dismiss

    @State private var isLoading = false
    @State private var searchResults = [SearchResultItem]()
    @State private var debounceTask: DispatchWorkItem?

    // Context menu state
    @State private var cityResultToVisit: SearchResult?
    @State private var showingRatingSheet = false
    @State private var cityToRate: SearchResult?
    @State private var showDeleteConfirmation = false
    @State private var cityToDelete: SearchResult?
    
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
                    List(sortedResults) { item in
                        switch item {
                        case .city(let result):
                            ZStack {
                                SearchListMember(result: result)
                                NavigationLink(destination: CityDetailView(cityId: Int(result.data_id) ?? 0)) {
                                    EmptyView()
                                }
                                .opacity(0)
                            }
                            .contextMenu {
                                contextMenuItems(for: result)
                            }
                            .listRowBackground(Color("Background"))
                        case .person(let person):
                            PersonSearchRow(person: person)
                                .listRowBackground(Color("Background"))
                        }
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
            .onChange(of: selectedCategory) {
                searchResults = []
                performSearch()
            }
            .sheet(item: $cityResultToVisit) { result in
                AddCityView(
                    baseResult: result,
                    isVisited: true,
                    onSave: { _ in
                        Task {
                            await viewModel.loadUserData()
                        }
                    }
                )
                .environmentObject(viewModel)
            }
            .sheet(isPresented: $showingRatingSheet) {
                if let result = cityToRate {
                    CityRatingView(
                        isPresented: $showingRatingSheet,
                        cityName: result.title,
                        country: result.country,
                        cityID: Int(result.data_id) ?? 0,
                        onRatingSelected: { rating in
                            Task {
                                await viewModel.updateCityRating(cityId: Int(result.data_id) ?? 0, rating: rating)
                            }
                        }
                    )
                    .presentationBackground(Color("Background"))
                }
            }
            .alert("Remove City", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    cityToDelete = nil
                }
                Button("Remove", role: .destructive) {
                    if let result = cityToDelete {
                        Task {
                            await viewModel.removeCityFromList(cityId: Int(result.data_id) ?? 0)
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to remove \(cityToDelete?.title ?? "this city")? This action cannot be undone.")
            }
        }
    }

    private var sortedResults: [SearchResultItem] {
        searchResults.sorted { a, b in
            switch (a, b) {
            case (.city(let cityA), .city(let cityB)):
                return cityA.population > cityB.population
            default:
                return false
            }
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
            Task {
                do {
                    let results = try await DatabaseManager.shared.searchCities(query: currentQuery)
                    self.searchResults = results.map { .city($0) }
                } catch {
                    self.searchResults = []
                }
                self.isLoading = false
            }

        case .countries:
            Task {
                do {
                    let results = try await DatabaseManager.shared.searchCountries(query: currentQuery)
                        .map { SearchResult(title: $0.name, subtitle: "", latitude: nil, longitude: nil, population: Int($0.population), country: "", admin: "", data_id: String($0.id)) }
                    self.searchResults = results.map { .city($0) }
                } catch {
                    self.searchResults = []
                }
                self.isLoading = false
            }

        case .people:
            Task {
                do {
                    let results = try await DatabaseManager.shared.searchPeople(query: currentQuery)
                    self.searchResults = results.map { .person($0) }
                } catch {
                    self.searchResults = []
                }
                self.isLoading = false
            }
        }
    }

    @ViewBuilder
    private func contextMenuItems(for result: SearchResult) -> some View {
        let cityId = Int(result.data_id) ?? 0
        let isVisited = viewModel.visitedCities.contains { $0.id == cityId }
        let isInBucket = viewModel.bucketListCities.contains { $0.id == cityId }

        if isVisited {
            Button {
                cityToRate = result
                showingRatingSheet = true
            } label: {
                Label("Change Rating", systemImage: "pencil")
            }
            Button(role: .destructive) {
                cityToDelete = result
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } else if isInBucket {
            Button {
                cityResultToVisit = result
            } label: {
                Label("Mark as Visited", systemImage: "checkmark.circle")
            }
            Button(role: .destructive) {
                Task {
                    await viewModel.removeCityFromList(cityId: cityId)
                }
            } label: {
                Label("Remove from Bucket List", systemImage: "bookmark.slash")
            }
        } else {
            Button {
                Task {
                    await viewModel.addCityToBucketList(cityId: cityId)
                }
            } label: {
                Label("Add to Bucket List", systemImage: "bookmark")
            }
            Button {
                cityResultToVisit = result
            } label: {
                Label("Mark as Visited", systemImage: "checkmark.circle")
            }
        }
    }
}

struct PersonSearchRow: View {
    let person: ProfileSearchResult

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: avatarURL) { phase in
                switch phase {
                case .empty:
                    Circle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                case .failure:
                    Circle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    Circle()
                        .fill(Color(.systemGray5))
                }
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                if let fullName = person.fullName, !fullName.isEmpty {
                    Text(fullName)
                        .font(.body)
                        .fontWeight(.medium)
                }
                if let username = person.username, !username.isEmpty {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color("Background"))
    }

    private var avatarURL: URL? {
        guard let path = person.avatarURL, !path.isEmpty else { return nil }
        return supabaseBaseURL.appendingPathComponent("storage/v1/object/public/avatars/\(path)")
    }
}

//#Preview {
//    SearchMainView()
//}

