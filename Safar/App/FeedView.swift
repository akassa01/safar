//
//  FeedView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-08.
//

import SwiftUI

struct FeedView: View {
    @EnvironmentObject var viewModel: FeedViewModel
    @State private var selectedPost: FeedPost?
    @State private var selectedUserId: String?
    @State private var selectedCityId: Int?
    @State private var reportingPost: FeedPost?
    @State private var blockingUserId: String?
    @State private var showBlockConfirmation = false

    private let currentUserId = DatabaseManager.shared.getCurrentUserId()

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                loadingView
            } else if viewModel.posts.isEmpty {
                emptyFeedView
            } else {
                feedList
            }
        }
        .background(Color("Background"))
        .navigationTitle("Feed")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.posts.isEmpty {
                await viewModel.loadFeed(refresh: true)
            }
        }
        .navigationDestination(item: $selectedPost) { post in
            PostDetailView(post: post, feedViewModel: viewModel)
        }
        .navigationDestination(item: $selectedUserId) { userId in
            UserProfileView(userId: userId)
        }
        .navigationDestination(item: $selectedCityId) { cityId in
            CityDetailView(cityId: cityId)
        }
        .sheet(item: $reportingPost) { post in
            ReportView(
                type: .post,
                targetId: String(post.id),
                targetDisplayName: "post"
            )
        }
        .alert("Block User?", isPresented: $showBlockConfirmation) {
            Button("Block", role: .destructive) {
                if let id = blockingUserId {
                    Task {
                        try? await BlockManager.shared.blockUser(userId: id)
                        viewModel.removePostsByUser(id)
                        blockingUserId = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) { blockingUserId = nil }
        } message: {
            Text("You won't see their posts and they won't be able to interact with yours.")
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
                    let isOwnPost = post.userId == currentUserId
                    FeedPostCard(
                        post: post,
                        onLikeTapped: {
                            Task { await viewModel.toggleLike(for: post) }
                        },
                        onUserTapped: {
                            selectedUserId = post.userId
                        },
                        onCityTapped: {
                            selectedCityId = post.cityId
                        },
                        onPostTapped: {
                            selectedPost = post
                        },
                        onReportPostTapped: isOwnPost ? nil : {
                            reportingPost = post
                        },
                        onBlockUserTapped: isOwnPost ? nil : {
                            blockingUserId = post.userId
                            showBlockConfirmation = true
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
        .environmentObject(FeedViewModel())
}
