//
//  UserProfileView.swift
//  safar
//
//  View for displaying a user's profile (own or another user's)
//

import SwiftUI

private struct CityNavItem: Hashable, Identifiable {
    let cityId: Int
    var id: Int { cityId }
}

struct UserProfileView: View {
    @StateObject private var viewModel: UserProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditProfile = false
    @State private var selectedPost: FeedPost?
    @State private var selectedCityId: CityNavItem?

    init(userId: String) {
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(userId: userId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading profile...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("Background"))
            } else if let profile = viewModel.profile {
                ScrollView {
                    VStack(spacing: 0) {
                        headerSection(profile: profile)

                        compactStatsSection

                        recentTripsSection

                        Spacer(minLength: 100)
                    }
                }
                .background(Color("Background"))
            } else {
                VStack {
                    Text("Profile not found")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    if let error = viewModel.error {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("Background"))
            }
        }
        .toolbar {
            if viewModel.isOwnProfile {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingEditProfile = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            if !viewModel.isOwnProfile {
                ToolbarItem(placement: .navigationBarTrailing) {
                    followButton
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .onDisappear {
                    Task { await viewModel.loadProfile() }
                }
        }
        .navigationDestination(item: $selectedPost) { post in
            PostDetailView(post: post, feedViewModel: nil)
        }
        .navigationDestination(item: $selectedCityId) { nav in
            CityDetailView(cityId: nav.cityId)
        }
        .task {
            await viewModel.loadProfile()
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private func headerSection(profile: UserProfile) -> some View {
        VStack(spacing: 16) {
            AvatarImageView(avatarPath: profile.avatarURL, size: 120, placeholderIconSize: 40)

            VStack(spacing: 4) {
                if let fullName = profile.fullName, !fullName.isEmpty {
                    Text(fullName)
                        .font(.title2)
                        .fontWeight(.bold)
                } else if let username = profile.username {
                    Text(username)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                } else {
                    Text("Anonymous")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }

                if let username = profile.username, profile.fullName != nil && !profile.fullName!.isEmpty {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }

            if let bio = profile.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(Color("Background"))
    }

    // MARK: - Compact Stats Section

    private var compactStatsSection: some View {
        HStack(spacing: 0) {
            NavigationLink(destination: FollowListView(userId: viewModel.userId, initialTab: .followers)) {
                VStack(spacing: 4) {
                    Text("\(viewModel.followerCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("followers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            NavigationLink(destination: FollowListView(userId: viewModel.userId, initialTab: .following)) {
                VStack(spacing: 4) {
                    Text("\(viewModel.followingCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("following")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            if viewModel.isOwnProfile {
                NavigationLink(destination: YourCitiesView()) {
                    VStack(spacing: 4) {
                        Text("\(viewModel.cities.count)")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("visited")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink(destination: UserCitiesListView(userId: viewModel.userId, cities: viewModel.cities, userName: viewModel.profile?.fullName ?? viewModel.profile?.username ?? "User")) {
                    VStack(spacing: 4) {
                        Text("\(viewModel.cities.count)")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("visited")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    // MARK: - Recent Trips Section

    private var recentTripsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Trips")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            if viewModel.isOwnProfile || viewModel.isFollowing {
                if viewModel.isLoadingPosts {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if viewModel.recentPosts.isEmpty {
                    Text("No trips yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.recentPosts) { post in
                            FeedPostCard(
                                post: post,
                                onLikeTapped: {
                                    Task { await viewModel.toggleLike(for: post) }
                                },
                                onUserTapped: { },
                                onCityTapped: { selectedCityId = CityNavItem(cityId: post.cityId) },
                                onPostTapped: { selectedPost = post }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.accentColor)
                    Text("Only \(viewModel.profile?.fullName ?? viewModel.profile?.username ?? "this user")'s followers can view their recent trips")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Follow Button

    private var followButton: some View {
        Button(action: {
            Task {
                await viewModel.toggleFollow()
            }
        }) {
            Group {
                if viewModel.isFollowLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(viewModel.isFollowing ? "Following" : "Follow")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .foregroundColor(viewModel.isFollowing ? .primary : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(viewModel.isFollowing ? Color(.systemGray5) : Color.accentColor)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isFollowLoading)
    }

}

#Preview {
    NavigationStack {
        UserProfileView(userId: "preview-user-id")
    }
}
