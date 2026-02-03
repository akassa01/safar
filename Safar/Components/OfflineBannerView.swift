//
//  OfflineBannerView.swift
//  safar
//

import SwiftUI

struct OfflineBannerView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.subheadline)
            Text("You're offline. Viewing cached data.")
                .font(.subheadline)
        }
        .foregroundColor(.white)
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color.orange)
    }
}

#Preview {
    VStack {
        OfflineBannerView()
        Spacer()
    }
}
