//
//  TopBar.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-05.
//

import SwiftUI

struct TopBar: View {
    
    @State private var showPopover = false
    
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
                    
                    Button(action: {
                        showPopover = true
                    }, label: {
                        Image(systemName: "bell")
                            .foregroundColor(Color.accentColor)
                    })
                    .popover(isPresented: $showPopover, arrowEdge: .top) {
                        
                        NotificationsView()
                            .presentationCompactAdaptation(.popover)
                            
                    }
                    .presentationBackground(Color("Background"))
                   
                    
                    NavigationLink(destination: {
                        ProfileView()
                    }, label: {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(Color.accentColor)
                    })
                   
                    
                    
                    NavigationLink(destination: {
                        SettingsView()
                    }, label: {
                        Image(systemName: "gearshape")
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
