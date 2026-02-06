//
//  CityListMember.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-08.
//

import SwiftUI

struct CityListMember: View {
    var index: Int
    var city: City
    var bucketList: Bool
    var locked: Bool
    var body: some View {
        HStack(alignment: .center) {
            Text(String(index + 1))
                .font(.title2)
                .bold(true)
                .frame(width: 40, alignment: .leading)
            VStack (alignment: .leading) {
                Text(city.displayName)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("\(city.admin), \(city.country)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(width: 250, alignment: .leading)
            .layoutPriority(1)
            
            if (!bucketList) {
                if (locked) {
                    Image(systemName: "lock.circle")
                        .foregroundColor(.accent)
                        .frame(width: 30)
                } else {
                    RatingCircle(rating: city.rating!)
                }
            }
        }
        .background(Color("Background"))
    }
}

//#Preview("City List w/ Items") {
//    CityListMember(city: City(name: "Vancouver", latitude: 40.7128, longitude: -74.0060, bucketList: false, isVisited: true, country: "Canada", admin: "British Columbia"))
//}

