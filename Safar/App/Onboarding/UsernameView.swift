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

                    HStack(spacing: 8) {
                        HStack {
                            Text("@")
                                .foregroundColor(.secondary)
                            TextField("username", text: $viewModel.username)
                                .textContentType(.username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .onChange(of: viewModel.username) { _, _ in
                                    viewModel.checkUsernameAvailability()
                                }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    viewModel.usernameValidator.isValid == false
                                        ? Color.red.opacity(0.6)
                                        : Color.clear,
                                    lineWidth: 1
                                )
                        )

                        // Availability indicator
                        if viewModel.usernameValidator.isChecking {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if let isValid = viewModel.usernameValidator.isValid {
                            Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isValid ? .accentColor : .red)
                                .font(.title3)
                        }
                    }

                    // Validation message
                    if let message = viewModel.usernameValidator.validationMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }

                Button(action: {
                    Task { await viewModel.saveUsername() }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Continue")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.usernameValidator.isValid == true ? Color.accentColor : Color(.systemGray4))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(viewModel.usernameValidator.isValid != true || viewModel.isLoading)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
    }
}
