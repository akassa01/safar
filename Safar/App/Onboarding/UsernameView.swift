//
//  UsernameView.swift
//  Safar
//
//  Onboarding step — choose a username with availability checking.
//

import SwiftUI

struct UsernameView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("Choose a username")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("This is your unique handle on Safar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack {
                        Text("@")
                            .foregroundColor(.secondary)
                        TextField("username", text: $viewModel.username)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onChange(of: viewModel.username) { _, _ in
                                viewModel.clearUsernameValidation()
                            }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                viewModel.usernameValidator.validationMessage != nil
                                    ? Color.red.opacity(0.6)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    )

                    // Validation message
                    if let message = viewModel.usernameValidator.validationMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Button(action: {
                    Task { await viewModel.checkAndSaveUsername() }
                }) {
                    Group {
                        if viewModel.usernameCheckState == .checking {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else if viewModel.usernameCheckState == .available {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                        } else {
                            Text("Continue")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isUsernameLocallyValid ? Color.accentColor : Color(.systemGray4))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.isUsernameLocallyValid || viewModel.usernameCheckState == .checking || viewModel.usernameCheckState == .available)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
    }
}
