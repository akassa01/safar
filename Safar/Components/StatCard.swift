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

    var body: some View {
        VStack {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.subheadline)
        }
        .foregroundColor(Color("Background"))
        .frame(maxWidth: .infinity,)
        .frame(height: 65)
        .padding()
        .background(Color.accentColor)
        .cornerRadius(20)
    }
}
