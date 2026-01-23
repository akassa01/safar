//
//  RecommendationCard.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-08.
//

import SwiftUI

struct RecommendationCard: View {
    let recommendation: CityRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(Color.accentColor.opacity(0.15))

                Image(systemName: "building.2.crop.circle")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor.opacity(0.6))
            }
            .frame(height: 80)

            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("\(recommendation.admin), \(recommendation.country)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Text(recommendation.matchReason)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .italic()
            }
            .padding(10)
        }
        .background(Color("Background"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}
