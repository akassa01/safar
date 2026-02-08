//
//  DetailDisplays.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-17.
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

struct StatusBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        Label(text, systemImage: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(color)
                    .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 2)
            )
    }
}

struct LockDisplay: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.circle")
                .foregroundColor(.white)
                .font(.system(size: 16))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.3))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
}

struct CommunityRatingBadge: View {
    let averageRating: Double
    let ratingCount: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.3.fill")
                .foregroundColor(.white.opacity(0.9))
                .font(.system(size: 12))
            Text(String(format: "%.1f", averageRating))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            Text("(\(ratingCount))")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.7))
                .shadow(color: .blue.opacity(0.3), radius: 3, x: 0, y: 2)
        )
    }
}
