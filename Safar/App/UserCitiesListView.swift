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
        VStack {
            Spacer(minLength: 24)
            Text("Cities Visited")
                .font(.title)
                .bold()

            List(sortedCities.enumerated().map({ $0 }), id: \.element) { i, city in
                ZStack {
                    CityListMember(index: i, city: city, bucketList: false, locked: cities.count < 5)
                    NavigationLink(destination: CityDetailView(cityId: city.id, isReadOnly: true, city: city, externalUserId: userId)) {
                        EmptyView()
                    }
                    .opacity(0)
                }
                .contentShape(Rectangle())
                .listRowBackground(Color("Background"))
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .background(Color("Background"))
        }
        .background(Color("Background"))
        .navigationTitle("Cities")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sortedCities: [City] {
        cities.sorted(by: { $0.rating ?? 0 > $1.rating ?? 0 })
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
