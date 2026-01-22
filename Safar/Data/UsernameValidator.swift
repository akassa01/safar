//
//  UsernameValidator.swift
//  Safar
//

import Foundation
import Supabase

// MARK: - Response Models

struct UsernameAvailabilityResponse: Codable {
    let available: Bool
    let error: String?
    let message: String
}

struct UsernameUpdateResponse: Codable {
    let success: Bool
    let error: String?
    let message: String
    let newUsername: String?
    let daysRemaining: Int?

    enum CodingKeys: String, CodingKey {
        case success, error, message
        case newUsername = "new_username"
        case daysRemaining = "days_remaining"
    }
}

struct CooldownStatusResponse: Codable {
    let canChange: Bool
    let lastChange: String?
    let daysRemaining: Int?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case canChange = "can_change"
        case lastChange = "last_change"
        case daysRemaining = "days_remaining"
        case error
    }
}

// MARK: - Username Errors

enum UsernameError: LocalizedError {
    case tooShort
    case tooLong
    case invalidCharacters
    case taken
    case cooldown(daysRemaining: Int)
    case sameUsername
    case unauthorized
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .tooShort:
            return "Username must be at least 3 characters"
        case .tooLong:
            return "Username must be 20 characters or less"
        case .invalidCharacters:
            return "Username can only contain letters, numbers, and underscores"
        case .taken:
            return "This username is already taken"
        case .cooldown(let days):
            return "You can change your username in \(days) days"
        case .sameUsername:
            return "This is already your username"
        case .unauthorized:
            return "You must be logged in"
        case .networkError(let message):
            return message
        }
    }
}

// MARK: - Username Validator

@MainActor
class UsernameValidator: ObservableObject {
    @Published var isChecking = false
    @Published var validationMessage: String?
    @Published var isValid: Bool?

    private var checkTask: Task<Void, Never>?

    // MARK: - Local Validation (instant)

    func validateFormat(_ username: String) -> UsernameError? {
        let trimmed = username.trimmingCharacters(in: .whitespaces)

        if trimmed.count < 3 {
            return .tooShort
        }

        if trimmed.count > 20 {
            return .tooLong
        }

        // Only alphanumeric and underscore
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        if trimmed.unicodeScalars.contains(where: { !allowedCharacters.contains($0) }) {
            return .invalidCharacters
        }

        return nil
    }

    // MARK: - Check Availability (debounced)

    func checkAvailability(_ username: String, currentUsername: String) {
        checkTask?.cancel()

        isValid = nil
        validationMessage = nil

        let trimmed = username.trimmingCharacters(in: .whitespaces)

        // Skip if same as current
        if trimmed == currentUsername {
            return
        }

        // Local validation first
        if let error = validateFormat(trimmed) {
            validationMessage = error.localizedDescription
            isValid = false
            return
        }

        // Debounce network call
        checkTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second

            guard !Task.isCancelled else { return }

            isChecking = true
            defer { isChecking = false }

            do {
                let response = try await checkUsernameAvailabilityRemote(trimmed)

                guard !Task.isCancelled else { return }

                isValid = response.available
                validationMessage = response.available ? nil : response.message
            } catch {
                guard !Task.isCancelled else { return }
                validationMessage = "Unable to check availability"
                isValid = nil
            }
        }
    }

    // MARK: - Remote API Calls

    private func checkUsernameAvailabilityRemote(_ username: String) async throws -> UsernameAvailabilityResponse {
        let response: UsernameAvailabilityResponse = try await supabase
            .rpc("check_username_availability", params: ["check_username": username])
            .execute()
            .value

        return response
    }

    func getCooldownStatus() async throws -> CooldownStatusResponse {
        let response: CooldownStatusResponse = try await supabase
            .rpc("get_username_cooldown_status")
            .execute()
            .value

        return response
    }

    func updateUsername(_ newUsername: String) async throws -> UsernameUpdateResponse {
        let response: UsernameUpdateResponse = try await supabase
            .rpc("update_username", params: ["new_username": newUsername])
            .execute()
            .value

        if !response.success, let errorCode = response.error {
            switch errorCode {
            case "too_short":
                throw UsernameError.tooShort
            case "too_long":
                throw UsernameError.tooLong
            case "invalid_chars":
                throw UsernameError.invalidCharacters
            case "taken":
                throw UsernameError.taken
            case "cooldown":
                throw UsernameError.cooldown(daysRemaining: response.daysRemaining ?? 30)
            case "same_username":
                throw UsernameError.sameUsername
            case "unauthorized":
                throw UsernameError.unauthorized
            default:
                throw UsernameError.networkError(response.message)
            }
        }

        return response
    }

    func reset() {
        checkTask?.cancel()
        isChecking = false
        validationMessage = nil
        isValid = nil
    }
}
