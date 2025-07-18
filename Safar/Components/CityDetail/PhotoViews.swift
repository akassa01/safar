//
//  PhotoViews.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-17.
//
import SwiftUI
import PhotosUI

struct PhotoThumbnailView: View {
    let image: UIImage?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

struct PhotosPickerView: View {
    @Binding var selectedPhotos: [PhotosPickerItem]
    let onPhotosSelected: ([UIImage]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            PhotosPicker(
                selection: $selectedPhotos,
                maxSelectionCount: 10,
                matching: .images
            ) {
                Label("Select Photos", systemImage: "photo.on.rectangle.angled")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGray6))
            }
            .navigationTitle("Add Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedPhotos) { oldPhotos, newPhotos in
                // Only process if we have new photos and aren't already processing
                if !newPhotos.isEmpty && !isProcessing && newPhotos != oldPhotos {
                    loadPhotos(newPhotos)
                }
            }
        }
    }
    
    private func loadPhotos(_ items: [PhotosPickerItem]) {
        guard !isProcessing else { return }
        
        isProcessing = true
        
        Task {
            var images: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            
            await MainActor.run {
                onPhotosSelected(images)
                isProcessing = false
                dismiss()
            }
        }
    }
}

struct PhotoViewerView: View {
    let photos: [Photo]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedIndex) {
                ForEach(photos.indices, id: \.self) { index in
                    if let image = photos[index].image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .navigationTitle("Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
