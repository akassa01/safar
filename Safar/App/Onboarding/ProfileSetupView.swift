//
//  ProfileSetupView.swift
//  Safar
//
//  Onboarding step — add a profile picture and bio (optional).
//

import PhotosUI
import Storage
import SwiftUI

struct ProfileSetupView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    @State private var imageSelection: PhotosPickerItem?
    @State private var avatarImage: AvatarImage?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("Set up your profile")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Add a photo and bio so other travelers can find you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            Spacer()

            VStack(spacing: 28) {
                // Avatar picker
                ZStack {
                    Group {
                        if let avatarImage {
                            avatarImage.image
                                .resizable()
                                .scaledToFill()
                        } else {
                            Circle()
                                .fill(Color(.systemGray5))
                                .overlay(
                                    Image(systemName: "person.crop.circle")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())

                    PhotosPicker(selection: $imageSelection, matching: .images) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                    }
                    .offset(x: 42, y: 42)
                }

                // Bio field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bio")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("Tell others about your travel experiences...", text: $viewModel.bio, axis: .vertical)
                        .lineLimit(3...5)
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

                VStack(spacing: 12) {
                    Button(action: {
                        Task { await viewModel.saveProfile(avatarData: avatarImage?.data) }
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
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)

                    Button(action: {
                        Task { await viewModel.saveProfile(avatarData: nil) }
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
        .onChange(of: imageSelection) { _, newValue in
            guard let newValue else { return }
            Task {
                if let loaded = try? await newValue.loadTransferable(type: AvatarImage.self) {
                    avatarImage = loaded
                }
            }
        }
    }
}
