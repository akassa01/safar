//
//  RecommendationCarousel.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-08.
//

import SwiftUI

struct RecommendationGrid: View {
    let recommendations: [CityRecommendation]
    @State private var showAll = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var visibleRecommendations: [CityRecommendation] {
        showAll ? recommendations : Array(recommendations.prefix(4))
    }

    private var hasMore: Bool {
        recommendations.count > 4
    }

    var body: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(visibleRecommendations) { recommendation in
                    NavigationLink(destination: CityDetailView(cityId: recommendation.id)) {
                        RecommendationCard(recommendation: recommendation)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)

            if hasMore {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAll.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(showAll ? "Show Less" : "Show More")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: showAll ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.accentColor)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(20)
                }
            }
        }
    }
}
