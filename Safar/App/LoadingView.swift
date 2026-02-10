//
//  LoadingView.swift
//  Safar
//
//  Splash screen shown during initial app load.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color("Background")

                // App Logo (centered relative to full screen, matching launch screen)
                Image("safar_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 840, maxHeight: 330)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }
}
