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

    var result: SearchResult
    var onMarkVisited: (SearchResult) -> Void

    @EnvironmentObject var viewModel: UserCitiesViewModel
    
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
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(.accent)
                }
                .buttonStyle(BorderlessButtonStyle())
                
            } else if !viewModel.visitedCities.contains(where: { $0.id == Int(result.data_id) }) {
                Button(action: {
                    Task {
                        await viewModel.addCityToBucketList(cityId: Int(result.data_id)!)
                    }
                }) {
                    Image(systemName: "bookmark")
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
                    onMarkVisited(result)
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.accent)
                        .imageScale(.large)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .background(Color("Background"))
    }
}
