//
//  UserProfileView.swift
//  safar
//
//  View for displaying another user's profile
//

import SwiftUI

struct UserProfileView: View {
    @StateObject private var viewModel: UserProfileViewModel
    @Environment(\.dismiss) private var dismiss

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
                        // Header Section
                        headerSection(profile: profile)

                        // Stats Section
                        statsSection

                        // Follow Counts Section
                        followCountsSection

                        // Cities Preview Section
                        citiesPreviewSection

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
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                followButton
            }
        }
        .task {
            await viewModel.loadProfile()
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private func headerSection(profile: UserProfile) -> some View {
        VStack(spacing: 16) {
            // Avatar
            AsyncImage(url: avatarURL(for: profile.avatarURL)) { phase in
                switch phase {
                case .empty:
                    avatarPlaceholder
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                case .failure:
                    avatarPlaceholder
                @unknown default:
                    avatarPlaceholder
                }
            }
            .frame(width: 120, height: 120)
            .overlay(
                Circle()
                    .stroke(Color(.systemBackground), lineWidth: 4)
            )

            // Name and Username
            VStack(spacing: 4) {
                if let fullName = profile.fullName, !fullName.isEmpty {
                    Text(fullName)
                        .font(.title2)
                        .fontWeight(.bold)
                } else if let username = profile.username {
                    Text(username)
                        .font(.title2)
                        .fontWeight(.bold)
                } else {
                    Text("Anonymous")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }

                if let username = profile.username, profile.fullName != nil && !profile.fullName!.isEmpty {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Bio
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

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                title: String(viewModel.profile?.visitedCitiesCount ?? 0),
                subtitle: "Cities"
            )
            StatCard(
                title: String(viewModel.profile?.visitedCountriesCount ?? 0),
                subtitle: "Countries"
            )
            StatCard(
                title: String(viewModel.continentsCount),
                subtitle: "Continents"
            )
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }

    // MARK: - Follow Counts Section

    private var followCountsSection: some View {
        HStack(spacing: 0) {
            NavigationLink(destination: FollowListView(userId: viewModel.userId, initialTab: .followers)) {
                VStack(spacing: 4) {
                    Text("\(viewModel.followerCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Followers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 40)

            NavigationLink(destination: FollowListView(userId: viewModel.userId, initialTab: .following)) {
                VStack(spacing: 4) {
                    Text("\(viewModel.followingCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Following")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom, 16)
    }

    // MARK: - Cities Preview Section

    private var citiesPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cities Visited")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if viewModel.cities.count > 5 {
                    NavigationLink(destination: UserCitiesListView(userId: viewModel.userId, cities: viewModel.cities)) {
                        HStack(spacing: 4) {
                            Text("See All")
                                .font(.subheadline)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.accentColor)
                    }
                }
            }
            .padding(.horizontal)

            if viewModel.cities.isEmpty {
                Text("No cities visited yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.previewCities, id: \.id) { city in
                        NavigationLink(destination: CityDetailView(cityId: city.id, isReadOnly: true, city: city)) {
                            UserCityRow(city: city)
                        }
                        .buttonStyle(.plain)

                        if city.id != viewModel.previewCities.last?.id {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Follow Button

    private var followButton: some View {
        Button(action: {
            Task {
                await viewModel.toggleFollow()
            }
        }) {
            if viewModel.isFollowLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Text(viewModel.isFollowing ? "Following" : "Follow")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(viewModel.isFollowing ? .primary : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(viewModel.isFollowing ? Color(.systemGray5) : Color.accentColor)
                    .cornerRadius(20)
            }
        }
        .disabled(viewModel.isFollowLoading)
    }

    // MARK: - Helpers

    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color(.systemGray5))
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 40))
            )
    }

    private func avatarURL(for path: String?) -> URL? {
        guard let path = path, !path.isEmpty else { return nil }
        return supabaseBaseURL
            .appendingPathComponent("storage/v1/object/public/avatars/\(path)")
    }
}

// MARK: - User City Row

struct UserCityRow: View {
    let city: City

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "building.2.fill")
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(city.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(city.country)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let rating = city.rating {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text(String(format: "%.1f", rating))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        UserProfileView(userId: "preview-user-id")
    }
}
