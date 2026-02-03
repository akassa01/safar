//
//  OfflineBannerView.swift
//  safar
//

import SwiftUI

struct OfflineBannerView: View {
    var lastSyncDate: Date?

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.subheadline)
                Text("You're offline. Viewing cached data.")
                    .font(.subheadline)
            }
            if let lastSync = lastSyncDate {
                Text("Last synced \(lastSync, format: .relative(presentation: .named))")
                    .font(.caption)
                    .opacity(0.9)
            }
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
        OfflineBannerView(lastSyncDate: Date().addingTimeInterval(-3600))
        OfflineBannerView(lastSyncDate: nil)
        Spacer()
    }
}
