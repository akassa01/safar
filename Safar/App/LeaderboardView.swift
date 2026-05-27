//
//  LeaderboardView.swift
//  safar
//
//  Top Visited cities and countries leaderboard view
//

import SwiftUI

enum LeaderboardTab: String, CaseIterable, Identifiable, IconRepresentable {
    case cities = "Cities"
    case countries = "Countries"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cities: return "building.2.fill"
        case .countries: return "flag.fill"
        }
    }
}

struct LeaderboardView: View {
    @EnvironmentObject var viewModel: LeaderboardViewModel
    @State private var selectedTab: LeaderboardTab
    @State private var showFilterSheet = false

    init(initialTab: LeaderboardTab = .cities) {
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                TabBarView<LeaderboardTab>(
                    selectedCategory: $selectedTab,
                    iconSize: 20
                )

                // Active filter chips
                if viewModel.hasActiveFilters {
                    activeFilterChips
                }

                // Content
                Group {
                    switch selectedTab {
                    case .cities:
                        cityLeaderboardContent
                    case .countries:
                        countryLeaderboardContent
                    }
                }
            }
        }
        .background(Color("Background"))
        .navigationTitle("Most Visited")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showFilterSheet = true
                } label: {
                    Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundColor(viewModel.hasActiveFilters ? .accentColor : .primary)
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            LeaderboardFilterSheet()
                .environmentObject(viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .task {
            if viewModel.topCities.isEmpty {
                await viewModel.loadTopCities()
                await viewModel.loadTopCountries()
            }
            if viewModel.availableCountries.isEmpty {
                await viewModel.loadAvailableCountries()
            }
        }
    }

    private var activeFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let continent = viewModel.selectedContinent {
                    ActiveFilterChip(label: continent) {
                        Task { await viewModel.selectContinent(nil) }
                    }
                }
                if let country = viewModel.selectedCountry {
                    ActiveFilterChip(label: country) {
                        Task { await viewModel.selectCountry(nil) }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var cityLeaderboardContent: some View {
        Group {
            if viewModel.isLoadingCities {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if viewModel.topCities.isEmpty {
                emptyStateView(message: "No visited cities yet")
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.topCities) { city in
                        NavigationLink(destination: CityDetailView(cityId: city.id)) {
                            LeaderboardCityRow(entry: city)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if city.id != viewModel.topCities.last?.id {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }

    private var countryLeaderboardContent: some View {
        Group {
            if viewModel.isLoadingCountries {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if viewModel.topCountries.isEmpty {
                emptyStateView(message: "No visited countries yet")
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.topCountries) { country in
                        NavigationLink(destination: CountryDetailView(country: country)) {
                            LeaderboardCountryRow(entry: country)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if country.id != viewModel.topCountries.last?.id {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }

    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Cities need at least 1 visit to appear")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Active Filter Chip

struct ActiveFilterChip: View {
    let label: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.accentColor.opacity(0.15))
        .foregroundColor(.accentColor)
        .cornerRadius(20)
    }
}

// MARK: - Filter Sheet

struct LeaderboardFilterSheet: View {
    @EnvironmentObject var viewModel: LeaderboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var countrySearch = ""

    var filteredCountries: [String] {
        if countrySearch.isEmpty { return viewModel.availableCountries }
        return viewModel.availableCountries.filter {
            $0.localizedCaseInsensitiveContains(countrySearch)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: Continent Section
                Section("Continent") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                title: "All",
                                isSelected: viewModel.selectedContinent == nil,
                                action: {
                                    Task { await viewModel.selectContinent(nil) }
                                }
                            )
                            ForEach(viewModel.continents, id: \.self) { continent in
                                FilterChip(
                                    title: continent,
                                    isSelected: viewModel.selectedContinent == continent,
                                    action: {
                                        Task { await viewModel.selectContinent(continent) }
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }

                // MARK: Country Section
                Section("Country") {
                    TextField("Search countries…", text: $countrySearch)
                        .autocorrectionDisabled()
                    if viewModel.availableCountries.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        ForEach(filteredCountries, id: \.self) { country in
                            Button {
                                let newValue = viewModel.selectedCountry == country ? nil : country
                                Task { await viewModel.selectCountry(newValue) }
                            } label: {
                                HStack {
                                    Text(country)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if viewModel.selectedCountry == country {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.hasActiveFilters {
                        Button("Clear") {
                            Task { await viewModel.clearAllFilters() }
                        }
                        .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LeaderboardView()
            .environmentObject(LeaderboardViewModel())
    }
}
