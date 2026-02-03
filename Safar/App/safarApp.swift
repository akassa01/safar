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
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showOfflineView = false
    @State private var isDataPreloaded = false

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading || (authManager.isAuthenticated && !isDataPreloaded) {
                    LoadingView()
                } else if authManager.isAuthenticated {
                    HomeView()
                        .environmentObject(userCitiesViewModel)
                } else {
                    AuthView()
                }
            }
            .environmentObject(authManager)
            .onChange(of: authManager.isLoading) { _, isLoading in
                // When auth check completes and user is authenticated, preload data
                if !isLoading && authManager.isAuthenticated && !isDataPreloaded {
                    Task {
                        await userCitiesViewModel.initializeWithCurrentUser()
                        isDataPreloaded = true
                    }
                }
            }
            .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    // User just signed in - preload their data
                    Task {
                        await userCitiesViewModel.initializeWithCurrentUser()
                        isDataPreloaded = true
                    }
                } else {
                    // User signed out - clear all data and cache
                    userCitiesViewModel.clearUserData(clearCache: true)
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
}
