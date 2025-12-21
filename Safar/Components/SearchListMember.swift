//
//  SearchListMember.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-05.
//

import SwiftUI

struct SearchListMember: View {
    @State private var showAlert = false
    @State private var alertTitle = "Error"
    @State private var alertMessage = ""
    
    @State private var showAddCitySheet = false
    @State private var addingToVisited = false
    @State private var tempCityResult: SearchResult? = nil
    
    var result: SearchResult
    
    @StateObject private var viewModel = UserCitiesViewModel()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.headline)
                Text(result.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // add to bucket
            if viewModel.bucketListCities.contains(where: { $0.id == Int(result.data_id) }) {
                Button (action: {
                    Task {
                        await viewModel.removeCityFromList(cityId: Int(result.data_id)!)
                    }
                }) {
                    Image(systemName: "list.clipboard.fill")
                        .foregroundColor(.accent)
                }
                .buttonStyle(BorderlessButtonStyle())
                
            } else if !viewModel.visitedCities.contains(where: { $0.id == Int(result.data_id) }) {
                Button(action: {
                    Task {
                        await viewModel.addCityToBucketList(cityId: Int(result.data_id)!)
                    }
                }) {
                    Image(systemName: "list.clipboard")
                        .foregroundColor(.accent)
                        .imageScale(.large)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
            // add to visited
            if viewModel.visitedCities.contains(where: { $0.id == Int(result.data_id) }) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accent)
            } else {
                Button(action: {
                    tempCityResult = result
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.accent)
                        .imageScale(.large)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .sheet(item: $tempCityResult) { result in
            AddCityView(
                baseResult: result,
                isVisited: true,
                onSave: { city in
                    Task {
                        await viewModel.loadUserData()
                    }
                    print("Successfully saved city: \(city.id)")
                }
            )
        }
        .padding(.vertical, 8)
        .background(Color("Background"))
        .task {
            await viewModel.initializeWithCurrentUser()
        }
    }
}
