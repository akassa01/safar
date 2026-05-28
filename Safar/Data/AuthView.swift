//
//  AuthView.swift
//  Safar
//f
//  Created by Arman Kassam on 2025-07-29.
//

import SwiftUI
import Supabase
import AuthenticationServices

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUp = true
    @State private var isLoading = false
    @State private var result: Result<Void, Error>?
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var forgotPasswordEmailSent = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Logo Section
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
                    
                    Text(isSignUp ? "Create your account" : "Sign in to your account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .frame(maxHeight: .infinity)
            
            // Form Section
            VStack(spacing: 20) {
                // Show success message for sign up, replacing the form
                if !isSignUp, forgotPasswordEmailSent {
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)

                        Text("Check Your Email")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("We sent a password reset link to \(email). Check your inbox and follow the link to reset your password.")
                            .foregroundColor(.secondary)
                            .font(.body)
                            .multilineTextAlignment(.center)

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                forgotPasswordEmailSent = false
                                result = nil
                            }
                        }) {
                            Text("Back to Sign In")
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
                } else if isSignUp, case .success = result {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("Account Created!")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Please check your email for a confirmation link to activate your account.")
                            .foregroundColor(.secondary)
                            .font(.body)
                            .multilineTextAlignment(.center)

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isSignUp = false
                                result = nil
                                password = ""
                                confirmPassword = ""
                            }
                        }) {
                            Text("Back to Sign In")
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
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        TextField("Enter your email", text: $email)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        HStack {
                            if showPassword {
                                TextField("Enter your password", text: $password)
                                    .textContentType(isSignUp ? .newPassword : .password)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField("Enter your password", text: $password)
                                    .textContentType(isSignUp ? .newPassword : .password)
                            }

                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    // Confirm Password Field (only for sign up)
                    if isSignUp {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            HStack {
                                if showConfirmPassword {
                                    TextField("Confirm your password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                } else {
                                    SecureField("Confirm your password", text: $confirmPassword)
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
                    }

                    // Error Message
                    if case .failure(let error) = result {
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }

                    // Sign In/Sign Up Button
                    Button(action: {
                        if isSignUp {
                            signUpButtonTapped()
                        } else {
                            signInButtonTapped()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isSignUp ? "Create Account" : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty || (isSignUp && confirmPassword.isEmpty))

                    // Forgot Password (only show for sign in)
                    if !isSignUp {
                        Button("Forgot Password?") {
                            forgotPasswordTapped()
                        }
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    }

                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(.systemGray4))
                        Text("or")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(.systemGray4))
                    }
                    .padding(.vertical, 10)

                    // Sign in with Apple Button
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { appleResult in
                            handleSignInWithApple(appleResult: appleResult)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(12)

                    // Terms of use notice (shown during sign up only)
                    if isSignUp {
                        HStack(spacing: 3) {
                            Text("By creating an account, you agree to Safar's")
                                .foregroundColor(.secondary)
                            Link("Terms of Use",
                                 destination: URL(string: "https://www.getsafar.ca/terms")!)
                        }
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    }

                    // Toggle between Sign In and Sign Up
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSignUp.toggle()
                            result = nil
                            forgotPasswordEmailSent = false
                            password = ""
                            confirmPassword = ""
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(.secondary)
                            Text(isSignUp ? "Sign In" : "Sign Up")
                                .foregroundColor(.accentColor)
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                    }
                    .padding(.top, 10)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
        .background(Color("Background").ignoresSafeArea())
    }
    
    func signInButtonTapped() {
        Task {
            isLoading = true
            defer { isLoading = false }

            let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
            do {
                try await supabase.auth.signIn(
                    email: trimmedEmail,
                    password: password
                )
                result = .success(())
            } catch {
                result = .failure(mappedSignInError(error))
            }
        }
    }

    func signUpButtonTapped() {
        guard password == confirmPassword else {
            result = .failure(AuthError.passwordMismatch)
            return
        }

        Task {
            isLoading = true
            defer { isLoading = false }

            let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
            do {
                try await supabase.auth.signUp(
                    email: trimmedEmail,
                    password: password,
                    redirectTo: URL(string: "safar://auth-callback")
                )
                try? await DatabaseManager.shared.acceptTerms()
                AnalyticsManager.shared.capture("user_signed_up", properties: ["method": "email"])
                result = .success(())
            } catch {
                result = .failure(error)
            }
        }
    }
    
    func handleSignInWithApple(appleResult: Result<ASAuthorization, Error>) {
        switch appleResult {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    isLoading = true
                    defer { isLoading = false }

                    do {
                        // Extract the identity token
                        guard let identityToken = appleIDCredential.identityToken,
                              let tokenString = String(data: identityToken, encoding: .utf8) else {
                            result = .failure(AuthError.appleSignInFailed)
                            return
                        }

                        // Sign in with Supabase using the Apple ID token
                        try await supabase.auth.signInWithIdToken(
                            credentials: .init(
                                provider: .apple,
                                idToken: tokenString
                            )
                        )

                        // Apple only provides full name on first sign-in, so save it to profiles table
                        if let fullName = appleIDCredential.fullName,
                           let givenName = fullName.givenName {
                            AnalyticsManager.shared.capture("user_signed_up", properties: ["method": "apple"])
                            let familyName = fullName.familyName ?? ""
                            let displayName = familyName.isEmpty ? givenName : "\(givenName) \(familyName)"
                            let currentUser = try await supabase.auth.session.user
                            try await supabase
                                .from("profiles")
                                .update(["full_name": displayName])
                                .eq("id", value: currentUser.id)
                                .execute()
                            // First sign-in = new account: record terms acceptance
                            try? await DatabaseManager.shared.acceptTerms()
                        }

                        result = .success(())
                    } catch {
                        result = .failure(error)
                    }
                }
            }
        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                result = nil
            } else {
                result = .failure(AuthError.appleSignInFailed)
            }
        }
    }
    
    private func mappedSignInError(_ error: Error) -> Error {
        if let authError = error as? Auth.AuthError {
            switch authError.errorCode {
            case .emailNotConfirmed:
                return AuthError.emailNotConfirmed
            case .invalidCredentials:
                return AuthError.invalidCredentials
            default:
                break
            }
        }
        return error
    }

    func forgotPasswordTapped() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                try await supabase.auth.resetPasswordForEmail(
                    email,
                    redirectTo: URL(string: "safar://auth-callback")
                )
                forgotPasswordEmailSent = true
                result = .success(())
            } catch {
                result = .failure(error)
            }
        }
    }
}

// Custom error enum for better error handling
enum AuthError: LocalizedError {
    case passwordMismatch
    case appleSignInFailed
    case emailNotConfirmed
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .passwordMismatch:
            return "Passwords do not match."
        case .appleSignInFailed:
            return "Apple Sign In failed. Please try again."
        case .emailNotConfirmed:
            return "Please confirm your email address before signing in. Check your inbox for the confirmation link we sent when you signed up."
        case .invalidCredentials:
            return "Incorrect email or password."
        }
    }
}

#Preview {
    AuthView()
}
