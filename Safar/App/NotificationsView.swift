//
//  NotificationsView.swift
//  Safar
//
//  In-app notification feed — shows social notifications (contact joined, new
//  follower, post liked/commented, comment liked/replied, city ranked) with
//  Instagram-style unread state: bold text + accent-tinted row + blue dot.
//  Tapping a row navigates to the relevant post, profile, or city.
//

import SwiftUI

// MARK: - Navigation Destination

/// Typed destination for tapping a notification row.
private enum NotificationDestination: Identifiable, Hashable {
    case post(userCityId: Int64)
    case userProfile(userId: String)
    case city(cityId: Int)

    var id: String {
        switch self {
        case .post(let id):        return "post-\(id)"
        case .userProfile(let id): return "profile-\(id)"
        case .city(let id):        return "city-\(id)"
        }
    }
}

// MARK: - NotificationsView

struct NotificationsView: View {
    @ObservedObject var viewModel: NotificationsViewModel
    @State private var destination: NotificationDestination?

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.notifications.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                errorView(message: error)
            } else if viewModel.notifications.isEmpty {
                emptyView
            } else {
                notificationsList
            }
        }
        .background(Color("Background"))
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadNotifications()
        }
        .refreshable {
            await viewModel.loadNotifications()
        }
        // MARK: Navigation destinations
        .navigationDestination(item: $destination) { dest in
            switch dest {
            case .post(let userCityId):
                PostNotificationLoader(userCityId: userCityId)
            case .userProfile(let userId):
                UserProfileView(userId: userId)
            case .city(let cityId):
                CityDetailView(cityId: cityId)
            }
        }
    }

    // MARK: - Subviews

    private var notificationsList: some View {
        List {
            ForEach(viewModel.notifications) { notif in
                NotificationRow(notification: notif)
                    .listRowBackground(
                        notif.read
                            ? Color("Background")
                            : Color.accentColor.opacity(0.06)
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparatorTint(Color(.systemGray5))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        destination = notif.navigationDestination
                    }
            }
        }
        .listStyle(.plain)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .font(.system(size: 44))
                .foregroundColor(.secondary)

            Text("No notifications yet")
                .font(.headline)

            Text("You'll see it here when someone likes your post, comments on your trip, replies to your comment, follows you, or ranks a city you've been to.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Try Again") {
                Task { await viewModel.loadNotifications() }
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.accentColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - NotificationRow

private struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(spacing: 12) {
            AvatarImageView(
                avatarPath: notification.actor?.avatarURL,
                size: 44,
                placeholderIconSize: 16
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(notificationMessage)
                    .font(.subheadline)
                    .fontWeight(notification.read ? .regular : .semibold)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(relativeTime(from: notification.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var actorName: String {
        notification.actor?.fullName
            ?? notification.actor?.username
            ?? "Someone"
    }

    private var notificationMessage: String {
        switch notification.type {
        case "contact_joined":
            return "\(actorName) joined Safar"

        case "new_follower":
            return "\(actorName) started following you"

        case "post_liked":
            if let city = notification.cityName {
                return "\(actorName) liked your trip to \(city)"
            }
            return "\(actorName) liked your trip"

        case "post_commented":
            let base = notification.cityName.map { "\(actorName) commented on your trip to \($0)" }
                ?? "\(actorName) commented on your trip"
            if let preview = notification.contentPreview {
                return "\(base): \"\(preview)\""
            }
            return base

        case "comment_liked":
            if let preview = notification.contentPreview {
                return "\(actorName) liked your comment: \"\(preview)\""
            }
            return "\(actorName) liked your comment"

        case "comment_replied":
            if let preview = notification.contentPreview {
                return "\(actorName) replied to your comment: \"\(preview)\""
            }
            return "\(actorName) replied to your comment"

        case "post_bookmarked":
            if let city = notification.cityName {
                return "\(actorName) saved your trip to \(city)"
            }
            return "\(actorName) saved your trip"

        case "city_ranked":
            if let city = notification.cityName {
                return "\(actorName) just ranked \(city)!"
            }
            return "\(actorName) ranked a city you've been to"

        default:
            return "New notification from \(actorName)"
        }
    }

    /// Converts an ISO 8601 timestamp to a human-readable relative string.
    private func relativeTime(from isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString)
                ?? ISO8601DateFormatter().date(from: isoString) else {
            return ""
        }

        let seconds = Int(-date.timeIntervalSinceNow)
        switch seconds {
        case 0..<60:           return "Just now"
        case 60..<3_600:       return "\(seconds / 60)m ago"
        case 3_600..<86_400:   return "\(seconds / 3_600)h ago"
        case 86_400..<172_800: return "Yesterday"
        default:               return "\(seconds / 86_400)d ago"
        }
    }
}

// MARK: - AppNotification navigation helper

private extension AppNotification {
    /// Determines where tapping this notification should navigate.
    var navigationDestination: NotificationDestination? {
        switch type {
        // Post-level actions → open the post
        case "post_liked", "post_commented", "comment_liked", "comment_replied", "post_bookmarked":
            if let ref = referenceId {
                return .post(userCityId: ref)
            }
            return actorDestination

        // Follower / contact → open their profile
        case "new_follower", "contact_joined":
            return actorDestination

        // City ranked → open the city detail
        case "city_ranked":
            if let ref = referenceId {
                return .city(cityId: Int(ref))
            }
            return nil

        default:
            return actorDestination
        }
    }

    private var actorDestination: NotificationDestination? {
        guard let id = actor?.id, !id.isEmpty else { return nil }
        return .userProfile(userId: id)
    }
}

// MARK: - PostNotificationLoader

/// Lazily loads a single FeedPost by its user_city.id and shows PostDetailView.
/// Used when navigating to a post from a notification tap.
private struct PostNotificationLoader: View {
    let userCityId: Int64

    @State private var post: FeedPost?
    @State private var isLoading = true
    @StateObject private var feedViewModel = FeedViewModel()

    var body: some View {
        Group {
            if let post = post {
                PostDetailView(post: post, feedViewModel: feedViewModel)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle("Loading…")
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.bubble")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Post not found")
                        .font(.headline)
                    Text("This trip may have been removed.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Post")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .task {
            post = try? await DatabaseManager.shared.getFeedPost(userCityId: userCityId)
            isLoading = false
        }
    }
}
