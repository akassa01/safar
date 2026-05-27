//
//  ToastView.swift
//  safar
//

import SwiftUI

struct ToastView: View {
    let message: String
    var onTap: (() -> Void)? = nil

    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.8))
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

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                VStack {
                    Spacer()
                    ToastView(message: message, onTap: onTap.map { action in
                        {
                            withAnimation { isPresented = false }
                            action()
                        }
                    })
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.easeInOut(duration: 0.3), value: isPresented)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String, duration: Double = 2.0, onTap: (() -> Void)? = nil) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message, duration: duration, onTap: onTap))
    }
}

#Preview {
    Text("Content")
        .toast(isPresented: .constant(true), message: "City details unavailable offline")
}
