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
    var onCityTapped: ((City) -> Void)? = nil

    @Environment(\.dismiss) var dismiss
    @State private var selectedCity: City? = nil

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
                        Button {
                            if let onCityTapped {
                                onCityTapped(city)
                            } else {
                                selectedCity = city
                            }
                        } label: {
                            Circle()
                                .fill((city.visited ?? false) ? Color.green : Color.yellow)
                                .frame(width: 16, height: 16)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                        .contentShape(Circle().scale(2.0))
                    }
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            .sheet(item: $selectedCity) { city in
                NavigationStack {
                    CityDetailView(cityId: city.id)
                        .environmentObject(viewModel)
                }
            }
          
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
                            .foregroundColor(.white)
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
                            Image(systemName: "xmark")
                                .font(.headline)
                                .padding(10)
                                .foregroundColor(.white)
                                .background(Color(.accent))
                                .bold()
                                .cornerRadius(20)
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
