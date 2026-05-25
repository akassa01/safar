//
//  OnboardingViewModel.swift
//  Safar
//
//  State machine managing the post-signup onboarding flow.
//

import Foundation
import Supabase
import os

enum OnboardingStep: Int, CaseIterable {
    case fullName    // 0
    case username    // 1
    case phoneNumber // 2
    case profile     // 3
    case findFriends // 4
    case welcome     // 5
}

enum UsernameCheckState {
    case idle, checking, available, taken
}

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep

    init() {
        // Apple provides the user's name during sign-in, so skip the full name step
        if case .string(let provider) = supabase.auth.currentSession?.user.appMetadata["provider"],
           provider == "apple" {
            currentStep = .username
        } else {
            currentStep = .fullName
        }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Full name step
    @Published var fullName = ""

    // Username step
    @Published var username = ""
    @Published var usernameCheckState: UsernameCheckState = .idle
    let usernameValidator = UsernameValidator()

    var isUsernameLocallyValid: Bool {
        usernameValidator.validateFormat(username.trimmingCharacters(in: .whitespaces)) == nil
    }

    // Phone number step
    @Published var phoneCountryCode = "+1"
    @Published var phoneNumber = ""

    // Profile step
    @Published var bio = ""

    var totalSteps: Int { OnboardingStep.allCases.count }
    var currentStepIndex: Int { currentStep.rawValue }

    // MARK: - Full Name

    var isFullNameValid: Bool {
        fullName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }

    func saveFullName() async {
        guard isFullNameValid else {
            errorMessage = "Please enter your full name."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let user = try await supabase.auth.session.user
            try await supabase
                .from("profiles")
                .upsert([
                    "id": user.id.uuidString,
                    "full_name": fullName.trimmingCharacters(in: .whitespacesAndNewlines)
                ])
                .execute()

            AnalyticsManager.shared.capture("onboarding_step_completed", properties: ["step": "full_name"])
            currentStep = .username
        } catch {
            Log.data.error("saveFullName failed: \(error)")
            errorMessage = "Failed to save name. Please try again."
        }

        isLoading = false
    }

    // MARK: - Username

    func clearUsernameValidation() {
        usernameValidator.validationMessage = nil
        usernameCheckState = .idle
    }

    func checkAndSaveUsername() async {
        let trimmed = username.trimmingCharacters(in: .whitespaces)

        if let formatError = usernameValidator.validateFormat(trimmed) {
            usernameValidator.validationMessage = formatError.localizedDescription
            return
        }

        usernameCheckState = .checking
        usernameValidator.validationMessage = nil

        do {
            let availability = try await usernameValidator.checkUsernameAvailabilityRemote(trimmed)

            if !availability.available {
                usernameCheckState = .taken
                usernameValidator.validationMessage = availability.message
                try? await Task.sleep(nanoseconds: 400_000_000)
                usernameCheckState = .idle
                return
            }

            let update = try await usernameValidator.updateUsername(trimmed)
            if update.success {
                usernameCheckState = .available
                AnalyticsManager.shared.capture("onboarding_step_completed", properties: ["step": "username"])
                try? await Task.sleep(nanoseconds: 600_000_000)
                currentStep = .phoneNumber
            } else {
                usernameCheckState = .idle
                usernameValidator.validationMessage = update.message
            }
        } catch {
            Log.data.error("checkAndSaveUsername failed: \(error)")
            usernameCheckState = .idle
            usernameValidator.validationMessage = error.localizedDescription
        }
    }

    // MARK: - Profile (avatar + bio)

    func saveProfile(avatarData: Data?) async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await supabase.auth.session.user
            var updates: [String: String] = [:]

            if let data = avatarData {
                let filePath = "\(UUID().uuidString).jpeg"
                try await supabase.storage
                    .from("avatars")
                    .upload(filePath, data: data, options: FileOptions(contentType: "image/jpeg"))
                updates["avatar_url"] = filePath
            }

            let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedBio.isEmpty {
                updates["bio"] = trimmedBio
            }

            if !updates.isEmpty {
                try await supabase
                    .from("profiles")
                    .update(updates)
                    .eq("id", value: user.id)
                    .execute()
            }

            AnalyticsManager.shared.capture("onboarding_step_completed", properties: ["step": "profile"])
            currentStep = .findFriends
        } catch {
            Log.data.error("saveProfile failed: \(error)")
            errorMessage = "Failed to save profile. Please try again."
        }

        isLoading = false
    }

    // MARK: - Phone Number

    var isPhoneNumberLocallyValid: Bool {
        phoneNumber.filter(\.isNumber).count >= 7
    }

    func savePhoneNumber() async {
        guard let e164 = ContactsManager.normalizePhone(
            countryCode: phoneCountryCode,
            number: phoneNumber
        ) else {
            errorMessage = "Please enter a valid phone number."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let hash = ContactsManager.sha256(e164)
            try await DatabaseManager.shared.savePhoneHash(hash)
            AnalyticsManager.shared.capture("onboarding_step_completed", properties: ["step": "phone_number"])
            currentStep = .profile
        } catch {
            Log.data.error("savePhoneNumber failed: \(error)")
            errorMessage = "Failed to save phone number. Please try again."
        }

        isLoading = false
    }

    func skipPhoneNumber() {
        AnalyticsManager.shared.capture("onboarding_step_skipped", properties: ["step": "phone_number"])
        currentStep = .profile
    }

    // MARK: - Find Friends

    func advanceToWelcome() {
        AnalyticsManager.shared.capture("onboarding_step_completed", properties: ["step": "find_friends"])
        currentStep = .welcome
    }

    // MARK: - Complete Onboarding

    func completeOnboarding() async {
        do {
            let user = try await supabase.auth.session.user
            try await supabase
                .from("profiles")
                .update(["onboarding_completed": true])
                .eq("id", value: user.id)
                .execute()
            AnalyticsManager.shared.capture("onboarding_step_completed", properties: ["step": "welcome"])
            AnalyticsManager.shared.capture("onboarding_completed")
        } catch {
            Log.data.error("completeOnboarding failed: \(error)")
        }
    }
}
