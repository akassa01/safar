//
//  RatingCircle.swift
//  safar
//
//  Reusable rating circle component - accent color circle with rating number
//

import SwiftUI

struct RatingCircle: View {
    let rating: Double
    var size: CGFloat = 45

    private var fontSize: CGFloat {
        size * 0.33
    }

    var body: some View {
        Text(String(format: "%.1f", rating))
            .font(.system(size: fontSize, weight: .bold))
            .foregroundStyle(Color("Background"))
            .frame(width: size, height: size)
            .background(Color.accent)
            .clipShape(Circle())
    }
}

#Preview {
    HStack(spacing: 16) {
        RatingCircle(rating: 9.2, size: 30)
        RatingCircle(rating: 8.5)
        RatingCircle(rating: 7.0, size: 60)
    }
    .padding()
}
