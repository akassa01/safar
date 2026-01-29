//
//  LoadingView.swift
//  Safar
//
//  Splash screen shown during initial app load.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // App Logo (matching launch screen)
                Image("safar_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280)
                    .padding(.horizontal, 24)

                Spacer()

                // Loading indicator
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                }
                .padding(.bottom, 100)
            }
        }
    }
}
