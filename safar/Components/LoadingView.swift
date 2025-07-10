//
//  ProgressView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-04.
//

import SwiftUI

struct LoadingView: View {
    @State private var animate = false

        var body: some View {
            let gradient = LinearGradient(
                gradient: Gradient(colors: [.clear, .accent.opacity(0.9), .clear]),
                startPoint: .leading,
                endPoint: .trailing
            )

            Image(systemName: "airplane")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundColor(.gray.opacity(0.4))
                .overlay(
                    Image(systemName: "airplane")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 90)
                        .foregroundColor(.accent)
                        .mask(
                            gradient
                                .frame(width: 100, height: 100)
                                .offset(x: animate ? 150 : -150)
                        )
                )
                .onAppear {
                    withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: false)) {
                        animate = true
                    }
                }
        }
}


#Preview {
    LoadingView()
}
