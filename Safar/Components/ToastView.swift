//
//  ToastView.swift
//  safar
//

import SwiftUI

struct ToastView: View {
    let message: String
    var onTap: (() -> Void)? = nil
    var undoAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            if let undo = undoAction {
                Spacer(minLength: 8)
                Button {
                    undo()
                } label: {
                    Text("Undo")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .frame(minWidth: 280)
        .background(Color.accentColor)
        .cornerRadius(25)
        .onTapGesture {
            onTap?()
        }
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let duration: Double
    var onTap: (() -> Void)? = nil
    var undoAction: (() -> Void)? = nil

    // Cancellable dismiss work so re-triggering resets the timer
    @State private var dismissWork: DispatchWorkItem?

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                VStack {
                    Spacer()
                    ToastView(
                        message: message,
                        onTap: onTap.map { action in
                            {
                                withAnimation { isPresented = false }
                                action()
                            }
                        },
                        undoAction: undoAction.map { action in
                            {
                                withAnimation { isPresented = false }
                                action()
                            }
                        }
                    )
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.easeInOut(duration: 0.3), value: isPresented)
                .onAppear {
                    scheduleDismiss()
                }
                .onChange(of: message) { _, _ in
                    scheduleDismiss()
                }
            }
        }
    }

    private func scheduleDismiss() {
        dismissWork?.cancel()
        let work = DispatchWorkItem {
            withAnimation {
                isPresented = false
            }
        }
        dismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
    }
}

extension View {
    func toast(
        isPresented: Binding<Bool>,
        message: String,
        duration: Double = 2.0,
        onTap: (() -> Void)? = nil,
        undoAction: (() -> Void)? = nil
    ) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message, duration: duration, onTap: onTap, undoAction: undoAction))
    }
}

#Preview {
    Text("Content")
        .toast(isPresented: .constant(true), message: "City details unavailable offline")
}
