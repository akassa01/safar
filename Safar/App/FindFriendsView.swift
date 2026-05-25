//
//  FindFriendsView.swift
//  Safar
//
//  Standalone "Find Friends" sheet — reachable from your own profile.
//  Reuses FindFriendsViewModel for contact matching and follow state.
//

import SwiftUI

struct FindFriendsView: View {
    @StateObject private var friendsVM = FindFriendsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if friendsVM.isLoading {
                    loadingView
                } else if friendsVM.contactsPermissionDenied {
                    permissionDeniedView
                } else if friendsVM.matches.isEmpty {
                    emptyStateView
                } else {
                    matchesList
                }
            }
            .navigationTitle("Find Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            await friendsVM.loadMatches()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Finding your contacts…")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Contacts access denied")
                .font(.headline)

            Text("To find friends, enable contacts access in Settings.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.accentColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No contacts on Safar yet")
                .font(.headline)

            Text("Keep traveling — we'll let you know when someone joins.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var matchesList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(friendsVM.matches) { match in
                    FindFriendRowView(
                        match: match,
                        isFollowing: friendsVM.followStates[match.id] ?? false,
                        isFollowLoading: friendsVM.followLoadingIds.contains(match.id)
                    ) {
                        Task { await friendsVM.toggleFollow(match) }
                    }

                    Divider()
                        .padding(.leading, 72)
                }
            }
        }
    }
}

// MARK: - FindFriendRowView

struct FindFriendRowView: View {
    let match: ProfileSearchResult
    let isFollowing: Bool
    let isFollowLoading: Bool
    let onFollow: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarImageView(
                avatarPath: match.avatarURL,
                size: 44,
                placeholderIconSize: 16
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(match.fullName ?? match.username ?? "Traveler")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let username = match.username {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            followButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var followButton: some View {
        if isFollowLoading {
            ProgressView()
                .frame(width: 90, height: 32)
        } else if isFollowing {
            Button(action: onFollow) {
                Text("Following")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(width: 90, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        } else {
            Button(action: onFollow) {
                Text("Follow")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 90, height: 32)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }
}
