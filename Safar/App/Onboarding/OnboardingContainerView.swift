//
//  OnboardingContainerView.swift
//  Safar
//
//  Step router for the onboarding flow with progress indicator.
//

import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: Double(viewModel.currentStepIndex + 1), total: Double(viewModel.totalSteps))
                .tint(.accentColor)
                .padding(.horizontal, 30)
                .padding(.top, 12)

            // Step content
            Group {
                switch viewModel.currentStep {
                case .fullName:
                    FullNameView(viewModel: viewModel)
                case .username:
                    UsernameView(viewModel: viewModel)
                case .profile:
                    ProfileSetupView(viewModel: viewModel)
                case .welcome:
                    WelcomeView(viewModel: viewModel, onComplete: onComplete)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
        }
        .background(Color("Background").ignoresSafeArea())
        .onChange(of: viewModel.currentStep) { _, _ in
            // Clear error when moving between steps
            viewModel.errorMessage = nil
        }
    }
}
