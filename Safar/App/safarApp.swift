//
//  safarApp.swift
//  safar
//
//  Created by Arman Kassam on 2025-06-30.
//

import SwiftUI
import PostHog
import UserNotifications

@main
struct safarApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var userCitiesViewModel = UserCitiesViewModel()
    @StateObject private var feedViewModel = FeedViewModel()
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showOfflineView = false
    @State private var isDataPreloaded = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        AnalyticsManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if authManager.isAuthenticated && !authManager.needsOnboarding && !authManager.needsPasswordReset {
                    HomeView()
                        .environmentObject(userCitiesViewModel)
                        .environmentObject(feedViewModel)
                        .environmentObject(leaderboardViewModel)
                        .opacity(isDataPreloaded ? 1 : 0)
                }

                if authManager.isLoading || (authManager.isAuthenticated && !authManager.needsOnboarding && !authManager.needsPasswordReset && !isDataPreloaded) {
                    LoadingView()
                } else if authManager.isAuthenticated && authManager.needsPasswordReset {
                    ResetPasswordView()
                } else if authManager.isAuthenticated && authManager.needsOnboarding {
                    OnboardingContainerView(onComplete: {
                        authManager.completeOnboarding()
                    })
                } else if !authManager.isAuthenticated {
                    AuthView()
                }
            }
            .environmentObject(authManager)
            .onChange(of: authManager.isLoading) { _, isLoading in
                // When auth check completes and user is authenticated (and done onboarding), preload data
                if !isLoading && authManager.isAuthenticated && !authManager.needsOnboarding && !authManager.needsPasswordReset && !isDataPreloaded {
                    preloadData()
                }
            }
            .onChange(of: authManager.needsOnboarding) { _, needsOnboarding in
                // When onboarding completes, preload data
                if !needsOnboarding && authManager.isAuthenticated && !authManager.needsPasswordReset && !isDataPreloaded {
                    preloadData()
                }
            }
            .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated && !authManager.needsOnboarding && !authManager.needsPasswordReset {
                    // User just signed in (returning user) - preload their data
                    preloadData()
                } else if !isAuthenticated {
                    // User signed out - clear all data and cache
                    userCitiesViewModel.clearUserData(clearCache: true)
                    feedViewModel.posts = []
                    leaderboardViewModel.topCities = []
                    leaderboardViewModel.topCountries = []
                    leaderboardViewModel.topTravelersByCities = []
                    leaderboardViewModel.topTravelersByCountries = []
                    isDataPreloaded = false
                }
            }
            .onChange(of: networkMonitor.isConnected) { _, isConnected in
                if isConnected && authManager.isAuthenticated {
                    // WiFi reconnected - reload all data
                    Task {
                        await userCitiesViewModel.loadUserData()
                    }
                } else if !isConnected && !authManager.isAuthenticated && !authManager.isLoading {
                    // Show offline view if not connected and not authenticated
                    showOfflineView = true
                }
            }
            .fullScreenCover(isPresented: $showOfflineView) {
                OfflineView {
                    showOfflineView = false
                }
            }
            .onOpenURL { url in
                Task {
                    // Exchange the deep-link URL (email confirmation, magic link, OAuth) for a
                    // session. Placed at scene level so it fires regardless of which view is
                    // currently active. AuthManager's auth listener handles navigation on success.
                    try? await supabase.auth.session(from: url)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active,
                      authManager.isAuthenticated,
                      !authManager.needsOnboarding else { return }
                Task { await syncContactHashesIfNeeded() }
            }
        }
    }

    /// Refreshes the contact waitlist at most once every 30 days.
    /// Calls the match-contacts edge function, which saves unmatched hashes
    /// (contacts not yet on Safar) server-side. Match results are discarded —
    /// this background sync is purely for keeping the notification waitlist fresh.
    /// Keyed per user so the interval resets correctly on sign-in/out.
    /// Silently skips if contacts permission has been denied.
    private func syncContactHashesIfNeeded() async {
        guard let userId = supabase.auth.currentUser?.id.uuidString else { return }

        let key = "contactHashLastSync_\(userId)"
        let lastSync = UserDefaults.standard.object(forKey: key) as? Date ?? .distantPast
        let thirtyDays: TimeInterval = 30 * 24 * 60 * 60

        guard Date().timeIntervalSince(lastSync) >= thirtyDays else { return }

        do {
            let hashes = try await ContactsManager().hashedPhoneNumbers()
            guard !hashes.isEmpty else { return }
            // Edge function matches + upserts unmatched hashes into the waitlist.
            // We don't need the match results here — discard them.
            _ = try await DatabaseManager.shared.matchContacts(hashedPhones: hashes)
            UserDefaults.standard.set(Date(), forKey: key)
            Log.data.info("Contact hashes synced for user \(userId)")
        } catch is ContactsPermissionError {
            // User hasn't granted contacts access — skip silently
        } catch {
            Log.data.error("Contact hash sync failed: \(error)")
        }
    }

    private func requestPushAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    private func preloadData() {
        guard !isDataPreloaded else { return }
        requestPushAuthorization()
        Task { await feedViewModel.loadFeed(refresh: true) }
        Task { await leaderboardViewModel.refresh() }
        Task { await BlockManager.shared.loadBlockedUsers() }
        Task {
            await userCitiesViewModel.initializeWithCurrentUser()
            isDataPreloaded = true
        }
    }
}
