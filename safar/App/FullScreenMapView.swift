//
//  FullScreenMapView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-05.
//

import SwiftUI
import MapKit
import SwiftData

enum mapType: String, CaseIterable {
    case visited = "Visited"
    case bucketList = "Bucket List"
    case all = "All"
}

struct FullScreenMapView: View {
    @State var isFullScreen: Bool
    @State var cameraPosition: MapCameraPosition
    @Binding var mapPresentation: mapType

    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<City> { $0.isVisited == true }) private var visitedCities: [City]
    @Query(filter: #Predicate<City> { $0.bucketList == true}) private var bucketListCities: [City]
    @Query private var allCities: [City]
    @Environment(\.dismiss) var dismiss
    
    private var mapPins: [City] {
        switch mapPresentation {
        case .visited:
            return visitedCities
        case .bucketList:
            return bucketListCities
        case .all:
            return allCities
        }
    }

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                ForEach(mapPins) { city in
                    Marker(city.name, systemImage: city.isVisited ? "suitcase.fill" : "star.fill", coordinate: city.coordinate)
                        .tint(city.isVisited ? .green : .yellow)
                    
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
          
            VStack {
                // Top bar with a "Close" button
                HStack {
                    // "Visited" Tag
                    Button(action: {
                        changeMapType()
                    }) {
                        Text(mapPresentation.rawValue)
                            .font(.headline)
                            .padding(10)
                            .foregroundColor(Color("Background"))
                            .background(Color(.accent))
                            .bold(true)
                            .cornerRadius(20)
                    }
                    Spacer()
                    
                    if isFullScreen {
                        // Close Button
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.primary)
                                .background(.thinMaterial, in: Circle())
                        }
                    }
                    
                }
                .padding()
                
                Spacer()
            }
        }
    }
    private func changeMapType() {
        switch mapPresentation {
        case(.all) : mapPresentation = .visited
        case(.bucketList) : mapPresentation = .all
        case(.visited): mapPresentation = .bucketList
        }
    }
}
//#Preview {
//  FullScreenMapView(isFullScreen: true)
//}
