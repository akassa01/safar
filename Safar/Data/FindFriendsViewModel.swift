//
//  FindFriendsViewModel.swift
//  Safar
//
//  Drives the "People you know on Safar" onboarding step. Hashes contacts,
//  calls the match-contacts Edge Function, stores contact hashes for future
//  reverse-lookup notifications, and manages follow state for matched profiles.
//

import Foundation
import Supabase

@MainActor
class FindFriendsViewModel: ObservableObject {
    @Published var matches: [ProfileSearchResult] = []
    @Published var isLoading = false
    @Published var contactsPermissionDenied = false
    @Published var followStates: [String: Bool] = [:]       // userId → isFollowing
    @Published var followLoadingIds: Set<String> = []

    private let contactsManager = ContactsManager()

    // MARK: - Load

    func loadMatches() async {
        isLoading = true
        contactsPermissionDenied = false

        do {
            let hashes = try await contactsManager.hashedPhoneNumbers()

            guard !hashes.isEmpty else {
                isLoading = false
                return
            }

            // Run contact matching and hash storage concurrently
            async let matchTask = DatabaseManager.shared.matchContacts(hashedPhones: hashes)
            async let saveTask: Void = DatabaseManager.shared.saveContactHashes(hashes)

            var results: [ProfileSearchResult]
            do {
                (results, _) = try await (matchTask, saveTask)
            } catch {
                // If matching fails, at least try to save hashes; if save fails it's also non-fatal
                Log.data.error("loadMatches concurrent tasks failed: \(error)")
                results = []
            }

            // Filter out the current user's own profile (safety guard)
            let currentUserId = supabase.auth.currentUser?.id.uuidString
            matches = results.filter { $0.id != currentUserId }

            // Default all matches to "not following" — these are contacts,
            // so the user almost certainly isn't following them yet.
            for match in matches {
                followStates[match.id] = false
            }

        } catch let permError as ContactsPermissionError {
            switch permError {
            case .denied, .restricted:
                contactsPermissionDenied = true
            }
        } catch {
            Log.data.error("loadMatches failed: \(error)")
            // Show empty state — don't crash the onboarding step
        }

        isLoading = false
    }

    // MARK: - Follow / Unfollow

    func toggleFollow(_ profile: ProfileSearchResult) async {
        let id = profile.id
        guard !followLoadingIds.contains(id) else { return }

        let wasFollowing = followStates[id] ?? false
        followLoadingIds.insert(id)

        // Optimistic update
        followStates[id] = !wasFollowing

        do {
            if wasFollowing {
                try await DatabaseManager.shared.unfollowUser(followingId: id)
            } else {
                try await DatabaseManager.shared.followUser(followingId: id)
            }
        } catch {
            // Revert optimistic update on failure
            followStates[id] = wasFollowing
            Log.data.error("toggleFollow failed for \(id): \(error)")
        }

        followLoadingIds.remove(id)
    }
}
