import PhotosUI
import Storage
import Supabase
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager

    @State var username = ""
    @State var fullName = ""
    @State var bio = ""
    @State var joinDate = Date()

    @State var isLoading = false
    @State var showingSignOutAlert = false
    @State var signOutError: String?
    @State var showingSignOutError = false

    @State var imageSelection: PhotosPickerItem?
    @State var avatarImage: AvatarImage?

    // Username change states
    @State private var originalUsername = ""
    @State private var originalBio = ""
    @State private var isEditingUsername = false
    @State private var showingUsernameChangeConfirmation = false
    @State private var cooldownStatus: CooldownStatusResponse?
    @State private var profileError: String?
    @State private var showingErrorAlert = false
    @StateObject private var usernameValidator = UsernameValidator()

    @FocusState private var isBioFocused: Bool

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
                            // Name (display only)
                            Text(fullName.isEmpty ? "Add your name" : fullName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(fullName.isEmpty ? .gray : .primary)

                            // Username with edit button
                            if isEditingUsername {
                                VStack(spacing: 8) {
                                    HStack(spacing: 8) {
                                        TextField("Username", text: $username)
                                            .font(.subheadline)
                                            .textContentType(.username)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                            .padding(10)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
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

                                    // Save/Cancel buttons for username
                                    HStack(spacing: 12) {
                                        Button {
                                            username = originalUsername
                                            isEditingUsername = false
                                            usernameValidator.reset()
                                        } label: {
                                            Text("Cancel")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 8)
                                                .background(Color(.systemGray5))
                                                .cornerRadius(8)
                                        }

                                        Button {
                                            saveUsernameChange()
                                        } label: {
                                            HStack(spacing: 4) {
                                                if isLoading {
                                                    ProgressView()
                                                        .scaleEffect(0.7)
                                                        .tint(.white)
                                                } else {
                                                    Text("Save")
                                                }
                                            }
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                            .background(Color.accentColor)
                                            .cornerRadius(8)
                                        }
                                        .disabled(isLoading || usernameValidator.isValid == false || username == originalUsername)
                                    }
                                    .padding(.top, 4)
                                }
                                .frame(maxWidth: 280)
                                .padding(.top, 8)
                            } else {
                                HStack(spacing: 6) {
                                    Text("@\(username.isEmpty ? "username" : username)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    Button {
                                        Task {
                                            await loadCooldownStatus()
                                        }
                                        isEditingUsername = true
                                    } label: {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    .background(Color("Background"))

                    // Bio Section
                    VStack(spacing: 12) {
                        HStack {
                            Text("Bio")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }

                        TextField("Tell others about your travel experiences...", text: $bio, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .focused($isBioFocused)
                            .onChange(of: isBioFocused) { _, focused in
                                if !focused && bio != originalBio {
                                    saveBio()
                                }
                            }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)

                    // Sign Out Button
                    VStack(spacing: 12) {
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
                    .padding(.horizontal)
                    .padding(.bottom, 24)

                    Spacer(minLength: 100)
                }
            }
            .background(Color("Background"))
            .contentShape(Rectangle())
            .onTapGesture {
                isBioFocused = false
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        do {
                            try await authManager.signOut()
                        } catch {
                            signOutError = error.localizedDescription
                            showingSignOutError = true
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Sign Out Failed", isPresented: $showingSignOutError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(signOutError ?? "An unknown error occurred")
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
            bio = profile.bio ?? ""
            originalBio = profile.bio ?? ""

            if let avatarURL = profile.avatarURL, !avatarURL.isEmpty {
                try await downloadImage(path: avatarURL)
            }

        } catch {
            debugPrint(error)
        }
    }

    private func saveUsernameChange() {
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
    }

    private func updateUsername() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await usernameValidator.updateUsername(username)
            if response.success {
                originalUsername = username
                isEditingUsername = false
                usernameValidator.reset()
            }
        } catch let error as UsernameError {
            profileError = error.localizedDescription
            showingErrorAlert = true
        } catch {
            profileError = "Failed to update username. Please try again."
            showingErrorAlert = true
        }
    }

    private func saveBio() {
        Task {
            do {
                let currentUser = try await supabase.auth.session.user

                try await supabase
                    .from("profiles")
                    .update(["bio": bio])
                    .eq("id", value: currentUser.id)
                    .execute()

                originalBio = bio
            } catch {
                debugPrint(error)
            }
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
                guard let loadedImage = try await imageSelection.loadTransferable(type: AvatarImage.self) else { return }
                avatarImage = loadedImage
                // Save avatar immediately after selection
                await saveAvatar(imageData: loadedImage.data)
            } catch {
                debugPrint(error)
            }
        }
    }

    private func saveAvatar(imageData: Data) async {
        do {
            let filePath = "\(UUID().uuidString).jpeg"

            try await supabase.storage
                .from("avatars")
                .upload(
                    filePath,
                    data: imageData,
                    options: FileOptions(contentType: "image/jpeg")
                )

            let currentUser = try await supabase.auth.session.user

            try await supabase
                .from("profiles")
                .update(["avatar_url": filePath])
                .eq("id", value: currentUser.id)
                .execute()
        } catch {
            debugPrint(error)
        }
    }

    private func downloadImage(path: String) async throws {
        let data = try await supabase.storage.from("avatars").download(path: path)
        avatarImage = AvatarImage(data: data)
    }
}

#Preview {
    ProfileView()
}
