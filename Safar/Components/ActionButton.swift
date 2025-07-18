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
            .padding(.vertical, 10)
            .padding(.horizontal, 25)
            .background(Color.accentColor)
            .cornerRadius(20)
            .bold(true)
        }
        .foregroundColor(Color("Background"))
    }
}
