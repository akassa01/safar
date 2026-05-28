//
//  TopBar.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-05.
//

import SwiftUI

struct TopBar: View {
    @ObservedObject var notificationsViewModel: NotificationsViewModel

    var body: some View {
        NavigationStack {
            HStack {
                Image(.transparentLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 45)
                    .scaleEffect(1.9)
                    .padding(.leading, 40)

                Spacer()

                HStack(spacing: 20) {
                    NavigationLink(destination: {
                        NotificationsView(viewModel: notificationsViewModel)
                    }, label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .foregroundColor(Color.accentColor)
                            if notificationsViewModel.unreadCount > 0 {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                            }
                        }
                    })

                }
                .font(.title2)
                .padding(.trailing)
            }
            .background(Color("Background"))
        }
    }
}

#Preview {
    TopBar(notificationsViewModel: NotificationsViewModel())
}
