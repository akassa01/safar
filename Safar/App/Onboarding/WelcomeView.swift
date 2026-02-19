//
//  WelcomeView.swift
//  Safar
//
//  Final onboarding step — welcome the user and enter the app.
//

import SwiftUI

struct WelcomeView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image("transparentLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)

                VStack(spacing: 8) {
                    Text("You're all set!")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Start discovering and tracking your travels around the world.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }

            Spacer()

            Button(action: {
                Task {
                    await viewModel.completeOnboarding()
                    onComplete()
                }
            }) {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
    }
}
