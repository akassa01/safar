//
//  FullScreenMapView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-05.
//

import SwiftUI
import MapKit

enum mapType: String, CaseIterable {
    case visited = "Visited"
    case bucketList = "Bucket List"
    case all = "All"
}

struct FullScreenMapView: View {
    @State var isFullScreen: Bool
    @State var cameraPosition: MapCameraPosition
    @Binding var mapPresentation: mapType
    
    @ObservedObject var viewModel: UserCitiesViewModel

    @Environment(\.dismiss) var dismiss
    
    private var mapPins: [City] {
        switch mapPresentation {
        case .visited:
            return viewModel.visitedCities
        case .bucketList:
            return viewModel.bucketListCities
        case .all:
            return viewModel.allUserCities
        }
    }

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                ForEach(mapPins) { city in
                    Annotation(city.displayName, coordinate: CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude)) {
                        Circle()
                            .fill((city.visited ?? false) ? Color.green : Color.yellow)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
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
