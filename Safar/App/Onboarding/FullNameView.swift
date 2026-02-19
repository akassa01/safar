//
//  FullNameView.swift
//  Safar
//
//  Onboarding step — enter your full name.
//

import SwiftUI

struct FullNameView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("What's your name?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("This is how other travelers will see you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Name")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("e.g. Arman Kassam", text: $viewModel.fullName)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }

                Button(action: {
                    Task { await viewModel.saveFullName() }
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
                    .background(viewModel.isFullNameValid ? Color.accentColor : Color(.systemGray4))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.isFullNameValid || viewModel.isLoading)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
    }
}
