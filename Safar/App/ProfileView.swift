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
                                TextField("Username", text: $username)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textContentType(.username)
                                    .textInputAutocapitalization(.never)
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
        Task {
            isLoading = true
            defer {
                isLoading = false
                isEditing = false
            }
            do {
                let imageURL = try await uploadImage()
                
                let currentUser = try await supabase.auth.session.user
                
                let updatedProfile = Profile(
                    username: username,
                    fullName: fullName,
                    avatarURL: imageURL
                    // bio: bio // Add if you extend your Profile model
                )
                
                try await supabase
                    .from("profiles")
                    .update(updatedProfile)
                    .eq("id", value: currentUser.id)
                    .execute()
            } catch {
                debugPrint(error)
            }
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
