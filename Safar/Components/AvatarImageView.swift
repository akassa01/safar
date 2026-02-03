//
//  AvatarImageView.swift
//  safar
//
//  Reusable avatar component that loads images from Supabase storage
//

import SwiftUI

struct AvatarImageView: View {
    let avatarPath: String?
    var size: CGFloat = 40
    var placeholderIconSize: CGFloat = 16

    @State private var loadedImage: Image?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image = loadedImage {
                image
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else if isLoading {
                Circle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.5)
                    )
            } else {
                Circle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: placeholderIconSize))
                    )
            }
        }
        .frame(width: size, height: size)
        .task(id: avatarPath) {
            await loadAvatar()
        }
    }

    private func loadAvatar() async {
        guard let path = avatarPath, !path.isEmpty else {
            loadedImage = nil
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await supabase.storage.from("avatars").download(path: path)
            if let uiImage = UIImage(data: data) {
                loadedImage = Image(uiImage: uiImage)
            }
        } catch {
            debugPrint("Failed to load avatar: \(error)")
            loadedImage = nil
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AvatarImageView(avatarPath: nil, size: 120, placeholderIconSize: 40)
        AvatarImageView(avatarPath: nil, size: 40, placeholderIconSize: 16)
    }
}
