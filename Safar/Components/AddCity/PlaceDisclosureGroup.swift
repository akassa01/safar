//
//  PlaceDisclosureGroup.swift
//  Safar
//
//  Created by Arman Kassam on 2025-07-22.
//

import SwiftUI

struct PlaceDisclosureGroup: View {
    let title: String
    @Binding var places: [Place]
    let category: PlaceCategory
    let color: Color
    let icon: String
    let onAdd: (PlaceCategory) -> Void
    
    var body: some View {
        DisclosureGroup("\(title) (\(places.count))") {
            ForEach(places, id: \.localKey) { place in
                PlaceRowInList(
                    place: place,
                    color: color,
                    icon: icon,
                    onRemove: {
                        places.removeAll { $0.localKey == place.localKey }
                    }
                )
            }
            
            Button("Add \(title)") {
                onAdd(category)
            }
            .foregroundColor(.accentColor)
        }
    }
}
