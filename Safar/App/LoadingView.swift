//
//  LoadingView.swift
//  Safar
//
//  Created by Assistant on 2025-01-27.
//

import SwiftUI

struct LoadingView: View {
    @State private var isLoading = true
    @State private var showConnectionError = false
    @State private var isAuthenticated = false
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
        .alert("Connection Error", isPresented: $showConnectionError) {
            Button("Retry") {
                Task {
                    await checkAuthenticationAndLoad()
                }
            }
            Button("Continue Offline") {
                loadingComplete = true
            }
        } message: {
            Text("Unable to connect to the server. Please check your internet connection and try again.")
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
        // Show loading for a minimum time to allow Supabase to respond
        let minimumLoadingTime: TimeInterval = 2.0
        let startTime = Date()
        
        do {
            // Check if we have a current session
            if let session = supabase.auth.currentSession {
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
            await MainActor.run {
                isLoading = false
                showConnectionError = true
            }
        }
    }
}
