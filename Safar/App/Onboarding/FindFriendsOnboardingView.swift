//
//  FindFriendsOnboardingView.swift
//  Safar
//
//  Onboarding step — requests Contacts permission, finds people the user already
//  knows who are on Safar, and lets them follow those people immediately.
//

import SwiftUI

struct FindFriendsOnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @StateObject private var friendsVM = FindFriendsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("People you know on Safar")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Follow them to see their travels")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 32)

            // Content
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
            .frame(maxHeight: .infinity)

            // Continue button — always enabled, step is skippable
            Button(action: { viewModel.advanceToWelcome() }) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
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
