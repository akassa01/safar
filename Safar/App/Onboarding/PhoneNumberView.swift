//
//  PhoneNumberView.swift
//  Safar
//
//  Onboarding step — optionally add a phone number so friends can find you.
//  Two separate fields (country code + local number) are combined and hashed
//  client-side before being sent to the server.
//

import SwiftUI

struct PhoneNumberView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var focusedField: Field?

    private enum Field { case countryCode, number }

    private var isLocallyValid: Bool {
        viewModel.phoneNumber.filter(\.isNumber).count >= 7
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: 8) {
                Text("What's your phone number?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Help friends find you on Safar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            Spacer()

            VStack(spacing: 20) {
                // Two-field input row
                HStack(spacing: 8) {
                    // Country code
                    TextField("+1", text: $viewModel.phoneCountryCode)
                        .keyboardType(.phonePad)
                        .focused($focusedField, equals: .countryCode)
                        .multilineTextAlignment(.center)
                        .frame(width: 64)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .countryCode ? Color.accentColor : Color.clear, lineWidth: 1.5)
                        )

                    // Local number
                    TextField("613 555 1234", text: $viewModel.phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .focused($focusedField, equals: .number)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .number ? Color.accentColor : Color.clear, lineWidth: 1.5)
                        )
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    Button(action: {
                        focusedField = nil
                        Task { await viewModel.savePhoneNumber() }
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
                        .background(isLocallyValid ? Color.accentColor : Color(.systemGray4))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isLocallyValid || viewModel.isLoading)

                    Button(action: {
                        focusedField = nil
                        viewModel.skipPhoneNumber()
                    }) {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
    }
}
