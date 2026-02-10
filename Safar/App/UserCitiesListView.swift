//
//  UserCitiesListView.swift
//  safar
//
//  Full list of another user's visited and bucket list cities
//

import SwiftUI

struct UserCitiesListView: View {
    let userId: String
    let cities: [City]
    let userName: String

    @State private var selectedTab: CityTab = .visited
    @State private var bucketListCities: [City] = []
    @State private var feedPosts: [FeedPost] = []
    @State private var selectedPost: FeedPost?
    @State private var isLoadingBucketList = false

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
    }

    var body: some View {
        VStack {
            TabBarView<CityTab>(
                selectedCategory: $selectedTab,
                iconSize: 22
            )

            List(currentSortedCities.enumerated().map({ $0 }), id: \.element) { i, city in
                ZStack {
                    CityListMember(index: i, city: city, bucketList: selectedTab == .bucketList, locked: currentCities.count < 5)
                    if selectedTab == .visited, let post = feedPosts.first(where: { $0.cityId == city.id }) {
                        NavigationLink(destination: PostDetailView(post: post, feedViewModel: nil)) {
                            EmptyView()
                        }
                        .opacity(0)
                    } else if selectedTab == .visited {
                        NavigationLink(destination: CityDetailView(cityId: city.id)) {
                            EmptyView()
                        }
                        .opacity(0)
                    }
                }
                .contentShape(Rectangle())
                .listRowBackground(Color("Background"))
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .background(Color("Background"))
        }
        .background(Color("Background"))
        .navigationTitle("\(userName)'s Cities")
        .task {
            await loadData()
        }
    }

    private var currentCities: [City] {
        switch selectedTab {
        case .visited: return cities
        case .bucketList: return bucketListCities
        }
    }

    private var currentSortedCities: [City] {
        currentCities.sorted(by: { $0.rating ?? 0 > $1.rating ?? 0 })
    }

    private func loadData() async {
        async let postsTask: () = loadFeedPosts()
        async let bucketTask: () = loadBucketList()
        _ = await (postsTask, bucketTask)
    }

    private func loadFeedPosts() async {
        do {
            feedPosts = try await DatabaseManager.shared.getUserFeedPosts(userId: userId, limit: 100)
        } catch {
            print("Error loading feed posts: \(error)")
        }
    }

    private func loadBucketList() async {
        isLoadingBucketList = true
        do {
            bucketListCities = try await DatabaseManager.shared.getBucketListCitiesForUser(userId: userId)
        } catch {
            print("Error loading bucket list: \(error)")
        }
        isLoadingBucketList = false
    }
}

#Preview {
    NavigationStack {
        UserCitiesListView(
            userId: "preview-user",
            cities: [],
            userName: "User"
        )
    }
}
