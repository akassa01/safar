//
//  AvatarImageView.swift
//  safar
//
//  Reusable avatar component that loads images from Supabase storage
//

import SwiftUI

@MainActor
final class AvatarCache {
    static let shared = AvatarCache()
    private let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 200
        c.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        return c
    }()
    private var inFlight: [String: Task<UIImage?, Never>] = [:]

    private init() {}

    func invalidate(path: String) {
        cache.removeObject(forKey: path as NSString)
    }

    func image(for path: String) async -> UIImage? {
        if let cached = cache.object(forKey: path as NSString) {
            return cached
        }

        if let existing = inFlight[path] {
            return await existing.value
        }

        let task = Task<UIImage?, Never> {
            do {
                let data = try await supabase.storage.from("avatars").download(path: path)
                guard let image = UIImage(data: data) else { return nil }
                let cost = Int(image.size.width * image.size.height * image.scale * image.scale) * 4
                cache.setObject(image, forKey: path as NSString, cost: cost)
                return image
            } catch is CancellationError {
                return nil
            } catch {
                return nil
            }
        }

        inFlight[path] = task
        let result = await task.value
        inFlight.removeValue(forKey: path)
        return result
    }
}

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
                    .fill(Color.accentColor)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
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

        loadedImage = nil
        isLoading = true
        defer { isLoading = false }

        if let uiImage = await AvatarCache.shared.image(for: path) {
            loadedImage = Image(uiImage: uiImage)
        } else {
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
