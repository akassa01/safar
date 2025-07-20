//
//  CityComparisonCard.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-16.
//

import SwiftUI
import Foundation

struct CityComparisonCard: View {
    let name: String
    let country: String
    let rating: Double?
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text("\(country)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let rating = rating {
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", rating))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                    Text("/ 10")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 120, height: 115)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    CityComparisonCard(name: "New York", country: "United States", rating: 9.2, isSelected: true)
}
