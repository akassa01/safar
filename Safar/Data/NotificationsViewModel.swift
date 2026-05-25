//
//  NotificationsViewModel.swift
//  Safar
//
//  Manages the in-app notification feed. Fetches notifications from Supabase,
//  marks them as read when the user opens the screen, and exposes an unread
//  count for the tab-bar badge.
//

import Foundation

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var unreadCount: Int = 0

    // MARK: - Load

    /// Fetches the latest notifications and marks them all as read.
    func loadNotifications() async {
        isLoading = true
        error = nil

        do {
            let fetched = try await DatabaseManager.shared.getNotifications(limit: 50, offset: 0)
            notifications = fetched

            // Mark as read after displaying
            let unreadIds = fetched.filter { !$0.read }.map(\.id)
            if !unreadIds.isEmpty {
                try await DatabaseManager.shared.markNotificationsRead(ids: unreadIds)
            }
            unreadCount = 0
        } catch {
            Log.data.error("loadNotifications failed: \(error)")
            self.error = "Couldn't load notifications. Pull to refresh."
        }

        isLoading = false
    }

    // MARK: - Badge

    /// Lightweight fetch for the tab-bar badge — does not affect read state.
    func refreshUnreadCount() async {
        do {
            unreadCount = try await DatabaseManager.shared.getUnreadNotificationCount()
        } catch {
            // Non-fatal; badge just won't update
            Log.data.error("refreshUnreadCount failed: \(error)")
        }
    }
}
