//
//  OfflineView.swift
//  Safar
//

import SwiftUI

struct OfflineView: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    var onRetry: () -> Void

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "wifi.slash")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)

                VStack(spacing: 8) {
                    Text("You're Offline")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Safar needs an internet connection to load your data. Please check your connection and try again.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .fontWeight(.semibold)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundColor(Color("Background"))
                    .cornerRadius(25)
                }
                .padding(.top, 8)

                Spacer()
                Spacer()
            }
        }
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            if isConnected {
                onRetry()
            }
        }
    }
}
