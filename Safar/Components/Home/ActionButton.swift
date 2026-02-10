//
//  ActionButton.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-02.
//

import Foundation
import SwiftUI

struct ActionButton: View {
    let title: String
    let systemImage: String
    var screenHeight: CGFloat = 800
    var action: () -> Void?

    var body: some View {
        Button(action: {
            action()
        }) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
                    .font(.subheadline)
            }
            .padding(.vertical, screenHeight * 0.012)
            .padding(.horizontal, screenHeight * 0.037)
            .background(Color.accentColor)
            .cornerRadius(20)
            .bold(true)
        }
        .foregroundColor(.white)
    }
}
