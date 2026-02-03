//
//  AuthManager.swift
//  Safar
//
//  Centralized authentication state management with persistent listener.
//

import Foundation
import Supabase

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var currentUserId: UUID?

    private var authTask: Task<Void, Never>?

    init() {
        // Check for cached session immediately (synchronous, works offline)
        if let session = supabase.auth.currentSession {
            isAuthenticated = true
            currentUserId = session.user.id
        }

        // Start persistent auth state listener
        startAuthListener()
    }

    private func startAuthListener() {
        authTask = Task {
            // Persistent listener - runs for entire app lifetime
            for await state in supabase.auth.authStateChanges {
                guard !Task.isCancelled else { break }

                switch state.event {
                case .initialSession, .signedIn:
                    self.isAuthenticated = state.session != nil
                    self.currentUserId = state.session?.user.id
                    self.isLoading = false

                case .signedOut:
                    self.isAuthenticated = false
                    self.currentUserId = nil
                    self.isLoading = false

                case .tokenRefreshed, .userUpdated:
                    // Session still valid, just refreshed
                    self.currentUserId = state.session?.user.id

                default:
                    break
                }
            }
        }
    }

    func signOut() async throws {
        // Clear local cache before signing out
        if let userId = currentUserId {
            CityCacheManager.shared.clearCache(for: userId)
        }
        try await supabase.auth.signOut()
        // State will be updated by the auth listener
    }

    deinit {
        authTask?.cancel()
    }
}
