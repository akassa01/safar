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

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading {
                    LoadingView()
                } else if authManager.isAuthenticated {
                    HomeView()
                        .environmentObject(userCitiesViewModel)
                } else {
                    AuthView()
                }
            }
            .environmentObject(authManager)
            .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    // User signed in - initialize their data
                    Task {
                        await userCitiesViewModel.initializeWithCurrentUser()
                    }
                } else {
                    // User signed out - clear all data
                    userCitiesViewModel.clearUserData()
                }
            }
            .onChange(of: networkMonitor.isConnected) { _, isConnected in
                // Show offline view if not connected and not authenticated
                if !isConnected && !authManager.isAuthenticated && !authManager.isLoading {
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
