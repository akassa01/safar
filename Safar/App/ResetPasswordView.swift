//
//  ResetPasswordView.swift
//  Safar
//

import SwiftUI
import Supabase

struct ResetPasswordView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var didSucceed = false

    private var passwordsMatch: Bool { newPassword == confirmPassword }
    private var isValid: Bool { newPassword.count >= 8 && passwordsMatch && !confirmPassword.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            // Logo section
            VStack(spacing: 30) {
                Spacer()

                Image("transparentLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)

                VStack(spacing: 8) {
                    Text("Welcome to Safar")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Choose a new password")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .frame(maxHeight: .infinity)

            // Form section
            VStack(spacing: 20) {
                if didSucceed {
                    // Success state
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("Password Updated!")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Your password has been changed. Sign in with your new password to continue.")
                            .foregroundColor(.secondary)
                            .font(.body)
                            .multilineTextAlignment(.center)

                        Button(action: {
                            Task { try? await authManager.signOut() }
                        }) {
                            Text("Sign In")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.top, 10)
                    }
                    .padding(.vertical, 20)
                } else {
                    // New password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        HStack {
                            if showNewPassword {
                                TextField("Enter new password", text: $newPassword)
                                    .textContentType(.newPassword)
                            } else {
                                SecureField("Enter new password", text: $newPassword)
                                    .textContentType(.newPassword)
                            }
                            Button(action: { showNewPassword.toggle() }) {
                                Image(systemName: showNewPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    // Confirm password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        HStack {
                            if showConfirmPassword {
                                TextField("Confirm new password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            } else {
                                SecureField("Confirm new password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            }
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    // Validation hint
                    if !newPassword.isEmpty && newPassword.count < 8 {
                        Text("Password must be at least 8 characters")
                            .foregroundColor(.red)
                            .font(.subheadline)
                    } else if !confirmPassword.isEmpty && !passwordsMatch {
                        Text("Passwords do not match")
                            .foregroundColor(.red)
                            .font(.subheadline)
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }

                    // Submit button
                    Button(action: { Task { await submit() } }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text("Reset Password")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || !isValid)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
        .background(Color("Background").ignoresSafeArea())
    }

    private func submit() async {
        isLoading = true
        errorMessage = nil
        do {
            try await supabase.auth.update(user: UserAttributes(password: newPassword))
            didSucceed = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    ResetPasswordView()
        .environmentObject(AuthManager())
}
