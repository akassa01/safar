//
//  UserCitiesListView.swift
//  safar
//
//  Full list of another user's visited cities
//

import SwiftUI

struct UserCitiesListView: View {
    let userId: String
    let cities: [City]

    var body: some View {
        List {
            ForEach(cities, id: \.id) { city in
                NavigationLink(destination: CityDetailView(cityId: city.id, isReadOnly: true, city: city)) {
                    UserCityRow(city: city)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color("Background"))
            }
        }
        .listStyle(.plain)
        .background(Color("Background"))
        .navigationTitle("Cities Visited")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        UserCitiesListView(
            userId: "preview-user",
            cities: []
        )
    }
}
