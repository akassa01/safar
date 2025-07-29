//
//  NotificationsView.swift
//  Safar
//
//  Created by Arman Kassam on 2025-07-23.
//

import SwiftUI

struct NotificationsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                HStack {
                    Image(systemName: "person.crop.circle")
                        .foregroundColor(Color.accentColor)
                    Text("John just visited London!")
                    
                }
                HStack {
                    Image(systemName: "person.crop.circle")
                        .foregroundColor(Color.accentColor)
                    Text("James just visited London!")
                    
                }
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(LocalizedStringKey("Notifications"))
            .background(Color("Background"))
        }
    }
}

#Preview {
    NotificationsView()
}
