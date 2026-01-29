//
//  RankBadge.swift
//  safar
//
//  Badge component for displaying ranking position (gold/silver/bronze for top 3)
//

import SwiftUI

struct RankBadge: View {
    let rank: Int

    var body: some View {
        ZStack {
            if rank <= 3 {
                Circle()
                    .fill(rankColor)
                    .frame(width: 36, height: 36)
                Text("\(rank)")
                    .font(.headline)
                    .bold()
                    .foregroundColor(.white)
            } else {
                Text("\(rank)")
                    .font(.headline)
                    .bold()
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
            }
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75) // Silver
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return .clear
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        RankBadge(rank: 1)
        RankBadge(rank: 2)
        RankBadge(rank: 3)
        RankBadge(rank: 4)
        RankBadge(rank: 10)
    }
    .padding()
}
