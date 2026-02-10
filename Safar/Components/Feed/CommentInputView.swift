//
//  CommentInputView.swift
//  Safar
//
//  Text input component for adding comments to posts
//

import SwiftUI

struct CommentInputView: View {
    @Binding var text: String
    let isLoading: Bool
    let onSubmit: () -> Void
    var replyingToUsername: String?
    var onCancelReply: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Replying-to banner
            if let username = replyingToUsername {
                HStack {
                    Text("Replying to @\(username)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button {
                        onCancelReply?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            HStack(spacing: 12) {
                TextField(replyingToUsername != nil ? "Write a reply..." : "Add a comment...", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .lineLimit(1...4)
                    .focused($isFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onSubmit()
                        }
                    }

                Button(action: onSubmit) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(canSubmit ? .accentColor : .secondary)
                    }
                }
                .disabled(!canSubmit || isLoading)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(24)
        }
    }

    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    VStack(spacing: 20) {
        CommentInputView(
            text: .constant(""),
            isLoading: false,
            onSubmit: {}
        )

        CommentInputView(
            text: .constant("Great post!"),
            isLoading: false,
            onSubmit: {},
            replyingToUsername: "johndoe",
            onCancelReply: {}
        )

        CommentInputView(
            text: .constant("Sending..."),
            isLoading: true,
            onSubmit: {}
        )
    }
    .padding()
}
