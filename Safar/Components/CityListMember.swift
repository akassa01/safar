//
//  CityListMember.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-08.
//

import SwiftUI

struct CityListMember: View {
    var city: City
    var bucketList: Bool
    var body: some View {
        HStack(alignment: .center) {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
        }
        .background(Color("Background"))
    }
}
