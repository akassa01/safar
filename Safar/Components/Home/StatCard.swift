//
//  StatCard.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-02.
//
import Foundation
import SwiftUI

struct StatCard: View {
    let title: String
    let subtitle: String
    var screenHeight: CGFloat = 800

    var body: some View {
        VStack {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.subheadline)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: screenHeight * 0.12)
        .padding(.vertical, 4)
        .background(Color.accentColor)
        .cornerRadius(20)
    }
}
