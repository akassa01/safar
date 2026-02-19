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
    @Published var needsOnboarding = false

    private var authTask: Task<Void, Never>?

    init() {
        // On a fresh install, UserDefaults is wiped but Keychain is not.
        // Sign out any stale Keychain session so the user sees the auth screen.
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if !hasLaunchedBefore {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            Task { try? await supabase.auth.signOut() }
        } else if let session = supabase.auth.currentSession {
            // Check for cached session immediately (synchronous, works offline)
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

                    // Check onboarding status
                    if let userId = state.session?.user.id {
                        await self.checkOnboardingStatus(userId: userId)
                    }
                    self.isLoading = false

                case .signedOut:
                    self.isAuthenticated = false
                    self.currentUserId = nil
                    self.needsOnboarding = false
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

    private func checkOnboardingStatus(userId: UUID) async {
        // Check local cache first — avoids any network call for returning users (works offline)
        let cacheKey = "onboarding_completed_\(userId.uuidString)"
        if UserDefaults.standard.bool(forKey: cacheKey) {
            self.needsOnboarding = false
            return
        }

        // NetworkMonitor.isConnected defaults to true and is updated asynchronously,
        // so we can't rely on it here. If offline, don't force onboarding — a user
        // with a valid cached session has already been through auth.
        do {
            let completed = try await DatabaseManager.shared.checkOnboardingCompleted(userId: userId.uuidString)
            if completed {
                UserDefaults.standard.set(true, forKey: cacheKey)
            }
            self.needsOnboarding = !completed
        } catch {
            // Network error: don't force onboarding for an authenticated returning user.
            // Only a missing profile row (brand-new user, no session cache) should
            // trigger onboarding — and those users won't have a cached session.
            self.needsOnboarding = false
        }
    }

    func completeOnboarding() {
        needsOnboarding = false
        // Cache locally so future offline launches skip the DB check entirely
        if let userId = currentUserId {
            UserDefaults.standard.set(true, forKey: "onboarding_completed_\(userId.uuidString)")
        }
    }

    func signOut() async throws {
        // Clear local cache before signing out
        if let userId = currentUserId {
            CityCacheManager.shared.clearCache(for: userId)
            UserDefaults.standard.removeObject(forKey: "onboarding_completed_\(userId.uuidString)")
        }
        try await supabase.auth.signOut()
        // State will be updated by the auth listener
    }

    deinit {
        authTask?.cancel()
    }
}
