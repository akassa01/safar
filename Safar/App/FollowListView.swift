//
//  FollowListView.swift
//  safar
//
//  View for displaying followers and following lists
//

import SwiftUI

enum FollowTab: String, CaseIterable {
    case followers = "Followers"
    case following = "Following"
}

struct FollowListView: View {
    let userId: String
    let initialTab: FollowTab

    @State private var selectedTab: FollowTab
    @State private var followers: [FollowUser] = []
    @State private var following: [FollowUser] = []
    @State private var isLoading = true
    @State private var error: Error?

    init(userId: String, initialTab: FollowTab = .followers) {
        self.userId = userId
        self.initialTab = initialTab
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab Selector
            HStack(spacing: 0) {
                ForEach(FollowTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text(tab.rawValue)
                                .font(.subheadline)
                                .fontWeight(selectedTab == tab ? .semibold : .regular)
                                .foregroundColor(selectedTab == tab ? .primary : .secondary)

                            Rectangle()
                                .fill(selectedTab == tab ? Color.accentColor : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Divider()

            // Content
            if isLoading {
                Spacer()
                ProgressView("Loading...")
                Spacer()
            } else {
                let users = selectedTab == .followers ? followers : following
                if users.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "person.2")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text(selectedTab == .followers ? "No followers yet" : "Not following anyone yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(users) { user in
                            NavigationLink(destination: UserProfileView(userId: user.id)) {
                                FollowUserRow(user: user)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color("Background"))
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .background(Color("Background"))
        .navigationTitle(selectedTab.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        isLoading = true
        do {
            async let followersTask = DatabaseManager.shared.getFollowers(userId: userId)
            async let followingTask = DatabaseManager.shared.getFollowing(userId: userId)

            let (loadedFollowers, loadedFollowing) = try await (followersTask, followingTask)
            followers = loadedFollowers
            following = loadedFollowing
        } catch {
            self.error = error
        }
        isLoading = false
    }
}

// MARK: - Follow User Row

struct FollowUserRow: View {
    let user: FollowUser

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AvatarImageView(avatarPath: user.avatarURL, size: 44, placeholderIconSize: 16)

            // User Info
            VStack(alignment: .leading, spacing: 2) {
                if let fullName = user.fullName, !fullName.isEmpty {
                    Text(fullName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else if let username = user.username {
                    Text(username)
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text("Anonymous")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    if let username = user.username, user.fullName != nil && !user.fullName!.isEmpty {
                        Text("@\(username)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("\(user.visitedCitiesCount ?? 0) cities")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

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
        FollowListView(userId: "preview-user")
    }
}
