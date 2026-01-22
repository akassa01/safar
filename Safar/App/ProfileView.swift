import PhotosUI
import Storage
import Supabase
import SwiftUI

struct ProfileView: View {
    @State var username = ""
    @State var fullName = ""
    @State var bio = ""
    @State var joinDate = Date()

    @State var isLoading = false
    @State var isEditing = false
    @State var showingSignOutAlert = false

    @State var imageSelection: PhotosPickerItem?
    @State var avatarImage: AvatarImage?

    // Username change states
    @State private var originalUsername = ""
    @State private var showingUsernameChangeConfirmation = false
    @State private var cooldownStatus: CooldownStatusResponse?
    @State private var profileError: String?
    @State private var showingErrorAlert = false
    @StateObject private var usernameValidator = UsernameValidator()

    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 16) {
                        // Profile Image
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
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                        )
                                }
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 4)
                            )
                            
                            // Edit Button Overlay
                            PhotosPicker(selection: $imageSelection, matching: .images) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.accentColor)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color(.systemBackground), lineWidth: 2)
                                    )
                            }
                            .offset(x: 40, y: 40)
                        }
                        
                        // User Info
                        VStack(spacing: 4) {
                            if isEditing {
                                TextField("Full Name", text: $fullName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            } else {
                                Text(fullName.isEmpty ? "Add your name" : fullName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(fullName.isEmpty ? .gray : .primary)
                            }
                            
                            if isEditing {
                                VStack(spacing: 4) {
                                    HStack(spacing: 8) {
                                        TextField("Username", text: $username)
                                            .font(.subheadline)
                                            .multilineTextAlignment(.center)
                                            .textContentType(.username)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                            .padding(8)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(usernameValidator.isValid == false ? Color.red : Color.clear, lineWidth: 1.5)
                                            )
                                            .onChange(of: username) { _, newValue in
                                                usernameValidator.checkAvailability(newValue, currentUsername: originalUsername)
                                            }

                                        // Availability indicator
                                        if usernameValidator.isChecking {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                        } else if let isValid = usernameValidator.isValid {
                                            Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .foregroundColor(isValid ? .accentColor : .red)
                                        }
                                    }

                                    // Validation message
                                    if let message = usernameValidator.validationMessage {
                                        Text(message)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }

                                    // Cooldown warning
                                    if let cooldown = cooldownStatus, !cooldown.canChange {
                                        Text("You can change your username in \(cooldown.daysRemaining ?? 0) days")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                                .frame(maxWidth: 220)
                            } else {
                                Text("@\(username.isEmpty ? "username" : username)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    .background(Color("Background"))
                    
                    // Bio Section
                    VStack(spacing: 16) {
                        HStack {
                            Text("About")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        if isEditing {
                            TextField("Tell others about your travel experiences...", text: $bio, axis: .vertical)
                                .lineLimit(3...6)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        } else {
                            Text(bio.isEmpty ? "Tell others about your travel experiences..." : bio)
                                .font(.body)
                                .foregroundColor(bio.isEmpty ? .gray : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        if isEditing {
                            Button(action: {
                                updateProfileButtonTapped()
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "checkmark")
                                        Text("Save Changes")
                                    }
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.accentColor)
                                .cornerRadius(20)
                            }
                            .disabled(isLoading)
                            
                            Button(action: {
                                // Reset to original values
                                username = originalUsername
                                isEditing = false
                            }) {
                                Text("Cancel")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(20)
                            }
                        } else {
                            Button(action: {
                                isEditing = true
                            }) {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("Edit Profile")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.accentColor)
                                .cornerRadius(20)
                            }
                        }
                        
                        // Settings and other actions
                        if !isEditing {
                            VStack(spacing: 8) {
                                ProfileActionRow(icon: "questionmark.circle", title: "Help & Support", action: {
                                    // Navigate to help
                                })
                                
                                ProfileActionRow(icon: "info.circle", title: "About Safar", action: {
                                    // Navigate to about
                                })
                                
                                Divider()
                                    .padding(.vertical, 8)
                                
                                Button(action: {
                                    showingSignOutAlert = true
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.right.square")
                                            .font(.system(size: 18))
                                            .foregroundColor(.red)
                                        Text("Sign Out")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.red)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color("Background"))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await supabase.auth.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Change Username?", isPresented: $showingUsernameChangeConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Change") {
                    Task {
                        await updateUsername()
                    }
                }
            } message: {
                Text("You can only change your username once every 30 days. Are you sure you want to change it to @\(username)?")
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(profileError ?? "An unknown error occurred")
            }
            .onChange(of: imageSelection) { _, newValue in
                guard let newValue else { return }
                loadTransferable(from: newValue)
            }
            .onChange(of: isEditing) { _, newValue in
                if newValue {
                    Task {
                        await loadCooldownStatus()
                    }
                } else {
                    usernameValidator.reset()
                }
            }
        }
        .task {
            await getInitialProfile()
        }
    }
    
    func getInitialProfile() async {
        do {
            let currentUser = try await supabase.auth.session.user
            
            let profile: Profile =
            try await supabase
                .from("profiles")
                .select()
                .eq("id", value: currentUser.id)
                .single()
                .execute()
                .value
            
            username = profile.username ?? ""
            originalUsername = profile.username ?? ""
            fullName = profile.fullName ?? ""
            // Add bio field to your Profile model if not already present
            // bio = profile.bio ?? ""
            
            if let avatarURL = profile.avatarURL, !avatarURL.isEmpty {
                try await downloadImage(path: avatarURL)
            }
            
        } catch {
            debugPrint(error)
        }
    }
    
    func updateProfileButtonTapped() {
        let usernameChanged = username != originalUsername

        // If username changed, check cooldown and show confirmation
        if usernameChanged {
            // Check if on cooldown
            if let cooldown = cooldownStatus, !cooldown.canChange {
                profileError = "You can change your username in \(cooldown.daysRemaining ?? 0) days"
                showingErrorAlert = true
                return
            }

            // Check validation
            if usernameValidator.isValid == false {
                profileError = usernameValidator.validationMessage ?? "Invalid username"
                showingErrorAlert = true
                return
            }

            // Show confirmation dialog
            showingUsernameChangeConfirmation = true
            return
        }

        // No username change, just save other profile fields
        saveProfileWithoutUsername()
    }

    private func saveProfileWithoutUsername() {
        Task {
            isLoading = true
            defer {
                isLoading = false
                isEditing = false
            }
            do {
                let imageURL = try await uploadImage()

                let currentUser = try await supabase.auth.session.user

                // Update profile without username (use original)
                let updatedProfile = Profile(
                    username: originalUsername,
                    fullName: fullName,
                    avatarURL: imageURL
                )

                try await supabase
                    .from("profiles")
                    .update(updatedProfile)
                    .eq("id", value: currentUser.id)
                    .execute()
            } catch {
                profileError = error.localizedDescription
                showingErrorAlert = true
            }
        }
    }

    private func updateUsername() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await usernameValidator.updateUsername(username)
            if response.success {
                originalUsername = username
                // Now save the rest of the profile
                saveProfileWithoutUsername()
            }
        } catch let error as UsernameError {
            profileError = error.localizedDescription
            showingErrorAlert = true
        } catch {
            profileError = "Failed to update username. Please try again."
            showingErrorAlert = true
        }
    }

    private func loadCooldownStatus() async {
        do {
            cooldownStatus = try await usernameValidator.getCooldownStatus()
        } catch {
            // Silently fail - will be caught on save attempt
        }
    }
    
    private func loadTransferable(from imageSelection: PhotosPickerItem) {
        Task {
            do {
                avatarImage = try await imageSelection.loadTransferable(type: AvatarImage.self)
            } catch {
                debugPrint(error)
            }
        }
    }
    
    private func downloadImage(path: String) async throws {
        let data = try await supabase.storage.from("avatars").download(path: path)
        avatarImage = AvatarImage(data: data)
    }
    
    private func uploadImage() async throws -> String? {
        guard let data = avatarImage?.data else { return nil }
        
        let filePath = "\(UUID().uuidString).jpeg"
        
        try await supabase.storage
            .from("avatars")
            .upload(
                filePath,
                data: data,
                options: FileOptions(contentType: "image/jpeg")
            )
        
        return filePath
    }
}

// Helper view for action rows
struct ProfileActionRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.accentColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

#Preview {
    ProfileView()
}
