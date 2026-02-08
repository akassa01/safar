//
//  TopBar.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-05.
//

import SwiftUI

struct TopBar: View {
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
                        UserProfileView(userId: DatabaseManager.shared.getCurrentUserId() ?? "")
                    }, label: {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(Color.accentColor)
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
    TopBar()
}
