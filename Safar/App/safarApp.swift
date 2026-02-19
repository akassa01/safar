//
//  safarApp.swift
//  safar
//
//  Created by Arman Kassam on 2025-06-30.
//

import SwiftUI

@main
struct safarApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var userCitiesViewModel = UserCitiesViewModel()
    @StateObject private var feedViewModel = FeedViewModel()
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showOfflineView = false
    @State private var isDataPreloaded = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if authManager.isAuthenticated && !authManager.needsOnboarding {
                    HomeView()
                        .environmentObject(userCitiesViewModel)
                        .environmentObject(feedViewModel)
                        .environmentObject(leaderboardViewModel)
                        .opacity(isDataPreloaded ? 1 : 0)
                }

                if authManager.isLoading || (authManager.isAuthenticated && !authManager.needsOnboarding && !isDataPreloaded) {
                    LoadingView()
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
                if !isLoading && authManager.isAuthenticated && !authManager.needsOnboarding && !isDataPreloaded {
                    preloadData()
                }
            }
            .onChange(of: authManager.needsOnboarding) { _, needsOnboarding in
                // When onboarding completes, preload data
                if !needsOnboarding && authManager.isAuthenticated && !isDataPreloaded {
                    preloadData()
                }
            }
            .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated && !authManager.needsOnboarding {
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
        }
    }

    private func preloadData() {
        guard !isDataPreloaded else { return }
        Task {
            async let cities: () = userCitiesViewModel.initializeWithCurrentUser()
            async let feed: () = feedViewModel.loadFeed(refresh: true)
            async let leaderboard: () = leaderboardViewModel.refresh()
            await cities
            await feed
            await leaderboard
            isDataPreloaded = true
        }
    }
}
