//
//  CityView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-10.
//

import SwiftUI

struct CityView: View {
    var city: City

    var body: some View {
        VStack {
            ZStack {
                Image("VancouverPicture")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 600, height: 300)
                    .clipped()
                    .ignoresSafeArea(edges: .all)
                
                VStack {
                    VisualEffectBlur(blurStyle: .light, intensity: 0.5)
                        .frame(width: 600, height: 100)
                        .clipShape(Rectangle())
                        .mask(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .black.opacity(0), location: 0.0),
                                    .init(color: .black.opacity(1), location: 0.3),
                                    .init(color: .black.opacity(1), location: 1.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                        .overlay {
                            HStack {
                                Spacer()
                                Text("\(city.name), \(city.country)")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .bold()
                                
                                Spacer()
                                
                                Text(String(100)).font(.subheadline)
                                    .bold()
                                    .foregroundStyle(Color("Background")).padding()
                                    .background(Color(.accent))
                                    .clipShape(Circle())
                                    .frame(width: 70)
                                Spacer()
                            }
                            .padding(.top, 30)
                        }
                }
                .padding(.top, 80)
               
            }
            Spacer()
            Text("images")
                .foregroundStyle(Color("Background"))
                .font(.title)
        }.background(Color("Background"))
    }
}


#Preview {
    CityView(city: City(name: "Vancouver", latitude: 40.7128, longitude: -74.0060, bucketList: false, isVisited: true, country: "Canada", admin: "British Columbia"))
}
