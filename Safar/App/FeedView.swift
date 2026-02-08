//
//  FeedView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-08.
//

import SwiftUI

/// Wrapper to make a user ID navigable
private struct UserNavigation: Hashable {
    let userId: String
}

/// Wrapper to make a city ID navigable
private struct CityNavigation: Hashable {
    let cityId: Int
}

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var selectedPost: FeedPost?
    @State private var navPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navPath) {
            Group {
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    loadingView
                } else if viewModel.posts.isEmpty {
                    emptyFeedView
                } else {
                    feedList
                }
            }
            .background(Color(.systemGray6))
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadFeed(refresh: true)
            }
            .navigationDestination(item: $selectedPost) { post in
                PostDetailView(post: post, feedViewModel: viewModel)
            }
            .navigationDestination(for: UserNavigation.self) { nav in
                UserProfileView(userId: nav.userId)
            }
            .navigationDestination(for: CityNavigation.self) { nav in
                CityDetailView(cityId: nav.cityId, isReadOnly: true)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading feed...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyFeedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No posts yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Follow other travelers to see their adventures here!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.posts) { post in
                    FeedPostCard(
                        post: post,
                        onLikeTapped: {
                            Task { await viewModel.toggleLike(for: post) }
                        },
                        onUserTapped: {
                            navPath.append(UserNavigation(userId: post.userId))
                        },
                        onCityTapped: {
                            navPath.append(CityNavigation(cityId: post.cityId))
                        },
                        onPostTapped: {
                            selectedPost = post
                        }
                    )
                    .onAppear {
                        Task { await viewModel.loadMoreIfNeeded(currentPost: post) }
                    }
                }

                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.loadFeed(refresh: true)
        }
    }
}

#Preview {
    FeedView()
}
