//
//  CategoryCard.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-16.
//
import SwiftUI

struct CategoryCard: View {
    let category: CityCategory
    let isSelected: Bool
    let showRating: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundColor(category.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(category.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if showRating {
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", category.baseRating))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                    Text("/ 10")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}
