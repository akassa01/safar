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
    case fullName
    case username
    case profile
    case welcome
}

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .fullName
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Full name step
    @Published var fullName = ""

    // Username step
    @Published var username = ""
    let usernameValidator = UsernameValidator()

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

            currentStep = .username
        } catch {
            Log.data.error("saveFullName failed: \(error)")
            errorMessage = "Failed to save name. Please try again."
        }

        isLoading = false
    }

    // MARK: - Username

    func checkUsernameAvailability() {
        usernameValidator.checkAvailability(username, currentUsername: "")
    }

    func saveUsername() async {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        guard usernameValidator.isValid == true else {
            errorMessage = usernameValidator.validationMessage ?? "Please choose a valid username."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await usernameValidator.updateUsername(trimmed)
            if response.success {
                currentStep = .profile
            } else {
                errorMessage = response.message
            }
        } catch {
            Log.data.error("saveUsername failed: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
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

            currentStep = .welcome
        } catch {
            Log.data.error("saveProfile failed: \(error)")
            errorMessage = "Failed to save profile. Please try again."
        }

        isLoading = false
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
        } catch {
            Log.data.error("completeOnboarding failed: \(error)")
        }
    }
}
