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
	    .foregroundStyle(Color.white)
            .frame(width: size, height: size)
            .background(Color.accent)
            .clipShape(Circle())
    }
}

struct CommunityRatingCircle: View {
    let rating: Double
    var ratingCount: Int?
    var size: CGFloat = 45

    private var fontSize: CGFloat {
        size * 0.33
    }

    private var badgeSize: CGFloat {
        size * 0.4
    }

    private var iconSize: CGFloat {
        size * 0.18
    }

    private var countFontSize: CGFloat {
        size * 0.2
    }

    var body: some View {
        Text(String(format: "%.1f", rating))
            .font(.system(size: fontSize, weight: .bold))
            .foregroundStyle(Color.white)
            .frame(width: size, height: size)
            .background(Color.white.opacity(0.25))
            .clipShape(Circle())
            .overlay(alignment: .topTrailing) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: iconSize))
                    .foregroundColor(.white)
                    .frame(width: badgeSize, height: badgeSize)
                    .clipShape(Circle())
                    .offset(x: size * 0.08, y: -size * 0.08)
            }
            .overlay(alignment: .bottomTrailing) {
                if let count = ratingCount {
                    Text("\(count)")
                        .font(.system(size: countFontSize, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: badgeSize, height: badgeSize)
                        .background(Color.accent)
                        .clipShape(Circle())
                        .offset(x: size * 0.08, y: size * 0.08)
                }
            }
    }
}

#Preview {
    HStack(spacing: 16) {
        RatingCircle(rating: 9.2, size: 30)
        RatingCircle(rating: 8.5)
        RatingCircle(rating: 7.0, size: 60)
    }
    .padding()

    HStack(spacing: 16) {
        CommunityRatingCircle(rating: 7.2, size: 30)
        CommunityRatingCircle(rating: 7.2)
        CommunityRatingCircle(rating: 7.2, size: 60)
    }
    .padding()
}
