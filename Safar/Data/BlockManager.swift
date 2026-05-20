//
//  BlockManager.swift
//  Safar
//
//  In-memory cache of blocked user IDs. Loaded once at login; updated
//  immediately on block/unblock so all feed/search/leaderboard filters
//  stay in sync without a full refresh.
//

import Foundation
import os

@MainActor
class BlockManager: ObservableObject {
    static let shared = BlockManager()

    @Published private(set) var blockedUserIds: Set<String> = []

    private init() {}

    func loadBlockedUsers() async {
        do {
            let ids = try await DatabaseManager.shared.getBlockedUserIds()
            blockedUserIds = Set(ids)
        } catch {
            Log.data.error("BlockManager.loadBlockedUsers failed: \(error)")
        }
    }

    func blockUser(userId: String) async throws {
        try await DatabaseManager.shared.blockUser(blockedId: userId)
        blockedUserIds.insert(userId)
    }

    func unblockUser(userId: String) async throws {
        try await DatabaseManager.shared.unblockUser(blockedId: userId)
        blockedUserIds.remove(userId)
    }

    func isBlocked(_ userId: String) -> Bool {
        blockedUserIds.contains(userId)
    }

    /// Filter a list of items by removing any whose userId keyPath matches a blocked ID.
    func filter<T>(_ items: [T], keyPath: KeyPath<T, String>) -> [T] {
        guard !blockedUserIds.isEmpty else { return items }
        return items.filter { !blockedUserIds.contains($0[keyPath: keyPath]) }
    }

    func reset() {
        blockedUserIds = []
    }
}
