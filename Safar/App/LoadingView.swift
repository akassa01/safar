//
//  LoadingView.swift
//  Safar
//
//  Created by Assistant on 2025-01-27.
//

import SwiftUI

struct LoadingView: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var isLoading = true
    @State private var isAuthenticated = false
    @State private var showOfflineView = false
    @State private var loadingComplete = false

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // App Logo (matching launch screen)
                Image("safar_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280)
                    .padding(.horizontal, 24)

                Spacer()

                // Loading indicator
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .task {
            await checkAuthenticationAndLoad()
        }
        .fullScreenCover(isPresented: $showOfflineView) {
            OfflineView {
                showOfflineView = false
                isLoading = true
                Task {
                    await checkAuthenticationAndLoad()
                }
            }
        }
        .fullScreenCover(isPresented: $loadingComplete) {
            if isAuthenticated {
                HomeView()
            } else {
                AuthView()
            }
        }
    }

    private func checkAuthenticationAndLoad() async {
        let minimumLoadingTime: TimeInterval = 2.0
        let startTime = Date()

        // First, check for a cached session (works offline - stored in Keychain)
        let hasExistingSession = supabase.auth.currentSession != nil

        // Check network connectivity
        if !networkMonitor.isConnected {
            await MainActor.run {
                isLoading = false
                if hasExistingSession {
                    // User is logged in but offline - show offline screen
                    isAuthenticated = true
                    showOfflineView = true
                } else {
                    // User is not logged in and offline - they need network to sign in
                    // Show offline screen (they can't do anything without network anyway)
                    showOfflineView = true
                }
            }
            return
        }

        // We have network - proceed with normal auth flow
        do {
            if hasExistingSession {
                isAuthenticated = true
            } else {
                // Listen for auth state changes
                for await state in supabase.auth.authStateChanges {
                    if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                        isAuthenticated = state.session != nil
                        break
                    }
                }
            }

            // Ensure minimum loading time
            let elapsedTime = Date().timeIntervalSince(startTime)
            if elapsedTime < minimumLoadingTime {
                try await Task.sleep(nanoseconds: UInt64((minimumLoadingTime - elapsedTime) * 1_000_000_000))
            }

            await MainActor.run {
                isLoading = false
                loadingComplete = true
            }

        } catch {
            // Network error during auth check - treat as offline
            await MainActor.run {
                isLoading = false
                isAuthenticated = hasExistingSession
                showOfflineView = true
            }
        }
    }
}
