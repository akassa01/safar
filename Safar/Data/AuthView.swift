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
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var result: Result<Void, Error>?
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
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
                
                // Error/Success Message
                if let result = result {
                    switch result {
                    case .success:
                        Text(isSignUp ? "Account created successfully! Please check your email for confirmation." : "Signed in successfully!")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    case .failure(let error):
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }
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
//                SignInWithAppleButton(
//                    onRequest: { request in
//                        request.requestedScopes = [.fullName, .email]
//                    },
//                    onCompletion: { result in
//                        handleSignInWithApple(result: result)
//                    }
//                )
//                .signInWithAppleButtonStyle(.black)
//                .frame(height: 50)
//                .cornerRadius(12)
                
                // Toggle between Sign In and Sign Up
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isSignUp.toggle()
                        result = nil
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
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
        .background(Color("Background"))
        .ignoresSafeArea()
        .onOpenURL(perform: { url in
            Task {
                do {
                    try await supabase.auth.session(from: url)
                    result = .success(())
                } catch {
                    result = .failure(error)
                }
            }
        })
    }
    
    func signInButtonTapped() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                try await supabase.auth.signIn(
                    email: email,
                    password: password
                )
                result = .success(())
            } catch {
                result = .failure(error)
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
            
            do {
                try await supabase.auth.signUp(
                    email: email,
                    password: password,
                    redirectTo: URL(string: "safar://auth-callback")
                )
                result = .success(())
            } catch {
                result = .failure(error)
            }
        }
    }
    
//    func handleSignInWithApple(result: Result<ASAuthorization, Error>) {
//        switch result {
//        case .success(let authorization):
//            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
//                Task {
//                    isLoading = true
//                    defer { isLoading = false }
//                    
//                    do {
//                        // Extract the identity token
//                        guard let identityToken = appleIDCredential.identityToken,
//                              let tokenString = String(data: identityToken, encoding: .utf8) else {
//                            result = .failure(AuthError.appleSignInFailed)
//                            return
//                        }
//                        
//                        // Sign in with Supabase using the Apple ID token
//                        try await supabase.auth.signInWithIdToken(
//                            credentials: .init(
//                                provider: .apple,
//                                idToken: tokenString
//                            )
//                        )
//                        
//                        self.result = .success(())
//                    } catch {
//                        self.result = .failure(error)
//                    }
//                }
//            }
//        case .failure(let error):
//            result = .failure(error)
//        }
//    }
    
    func forgotPasswordTapped() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                try await supabase.auth.resetPasswordForEmail(
                    email,
                    redirectTo: URL(string: "safar://auth-callback")
                )
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
    
    var errorDescription: String? {
        switch self {
        case .passwordMismatch:
            return "Passwords do not match"
        case .appleSignInFailed:
            return "Apple Sign In failed. Please try again."
        }
    }
}

#Preview {
    AuthView()
}
