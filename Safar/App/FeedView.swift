//
//  FeedView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-08.
//

import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var selectedPost: FeedPost?

    var body: some View {
        NavigationStack {
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
                            // Navigate to user profile - handled separately
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPost = post
                    }
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
