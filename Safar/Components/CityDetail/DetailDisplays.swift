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

