//
//  AppDelegate.swift
//  safar
//
//  Handles APNs device token registration and push notification tap routing.
//
//  Deep linking: When the user taps a push notification, AppDelegate parses
//  the type + reference_id from the payload and updates PushNotificationRouter.
//  HomeView observes pendingDestination and presents the right sheet.
//
//  To add a new deep link destination:
//    1. Add a case to PushNotificationDestination
//    2. Add a case to PushNotificationRouter.destination(from:referenceId:)
//    3. Add a handler in HomeView's .onChange(of: pushRouter.pendingDestination)

import UIKit
import UserNotifications

// MARK: - Push notification destination

enum PushNotificationDestination: Equatable {
    /// A friend visited this city / ranked this city → navigate to CityDetailView
    case cityDetail(cityId: Int)
    /// Engagement on a post or comment → navigate to PostDetailView
    case postDetail(userCityId: Int)
    /// A user followed you / a contact joined → navigate to their UserProfileView
    case userProfile(userId: String)
}

// MARK: - Router

/// Singleton observable bridge between AppDelegate and SwiftUI navigation.
/// Views observe `pendingDestination` and clear it after handling.
class PushNotificationRouter: ObservableObject {
    static let shared = PushNotificationRouter()

    @Published var pendingDestination: PushNotificationDestination?

    /// Maps a notification payload to a typed destination.
    /// Returns nil for unknown types — safe to ignore.
    func destination(from type: String, referenceId: Any?, actorId: Any? = nil) -> PushNotificationDestination? {
        switch type {

        // ── City screens ──────────────────────────────────────────────────
        case "bucket_list_friend_visit", "city_ranked":
            guard let referenceId else { return nil }
            let id = (referenceId as? Int) ?? Int("\(referenceId)".split(separator: ".").first ?? "") ?? 0
            return .cityDetail(cityId: id)

        // ── Post / comment screens ────────────────────────────────────────
        case "post_bookmarked", "post_liked", "post_commented", "comment_replied", "comment_liked":
            guard let referenceId else { return nil }
            let id = (referenceId as? Int) ?? Int("\(referenceId)".split(separator: ".").first ?? "") ?? 0
            return .postDetail(userCityId: id)

        // ── Profile screens ───────────────────────────────────────────────
        case "new_follower", "contact_joined":
            guard let actorId else { return nil }
            return .userProfile(userId: "\(actorId)")

        default:
            return nil
        }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Register as notification delegate early so foreground + tap callbacks fire
        UNUserNotificationCenter.current().delegate = notificationDelegate
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task {
            try? await DatabaseManager.shared.saveDeviceToken(token)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Log.app.error("Failed to register for remote notifications: \(error)")
    }

    // Keep a strong reference to the notification delegate
    private let notificationDelegate = SafarNotificationDelegate()
}

// MARK: - UNUserNotificationCenterDelegate

/// Separated from AppDelegate to keep each class focused.
private class SafarNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    /// Show banner + sound even when the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    /// User tapped a push notification — route to the right screen.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let type = userInfo["type"] as? String {
            let referenceId = userInfo["reference_id"]
            let actorId     = userInfo["actor_id"]
            if let destination = PushNotificationRouter.shared.destination(from: type, referenceId: referenceId, actorId: actorId) {
                DispatchQueue.main.async {
                    PushNotificationRouter.shared.pendingDestination = destination
                }
            }
        }
        completionHandler()
    }
}
