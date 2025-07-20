//
//  SearchListMember.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-05.
//

import SwiftUI
import SwiftData

struct SearchListMember: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<City> { $0.isVisited == true }) private var visitedCities: [City]
    @Query(filter: #Predicate<City> { $0.bucketList == true}) private var bucketListCities: [City]
    
    @State private var showAlert = false
    @State private var alertTitle = "Error"
    @State private var alertMessage = ""
    
    @State private var showAddCitySheet = false
    @State private var addingToVisited = false
    @State private var tempCityResult: SearchResult? = nil
    
    var result: SearchResult
    
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
            if bucketListCities.contains(where: { $0.name == result.title && $0.latitude == result.latitude && $0.longitude == result.longitude}) {
                Button (action: {
                    unsaveBucket(name: result.title,  latitude: result.latitude,
                                 longitude: result.longitude)
                    
                }) {
                    Image(systemName: "list.clipboard.fill")
                        .foregroundColor(.accent)
                }
                .buttonStyle(BorderlessButtonStyle())
                
            } else if !visitedCities.contains(where: { $0.name == result.title && $0.latitude == result.latitude && $0.longitude == result.longitude}) {
                Button(action: {
                    saveCity(
                        name: result.title,
                        latitude: result.latitude,
                        longitude: result.longitude,
                        country: result.country,
                        admin: result.admin,
                        bucket: true,
                        visit: false
                    )
                }) {
                    Image(systemName: "list.clipboard")
                        .foregroundColor(.accent)
                        .imageScale(.large)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
            // add to visited
            if visitedCities.contains(where: { $0.name == result.title && $0.latitude == result.latitude && $0.longitude == result.longitude}) {
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
                    let name = city.name
                    let latitude = city.latitude
                    let longitude = city.longitude
                    let fetchDescriptor = FetchDescriptor<City>(predicate: #Predicate { $0.name == name && $0.latitude == latitude && $0.longitude == longitude })

                    do {
                        let existingCities = try modelContext.fetch(fetchDescriptor)
                        if let existingCity = existingCities.first {
                            modelContext.delete(existingCity)
                            modelContext.insert(city)
                                try modelContext.save()
                            print("Updated existing city \(city.name) to visited.")
                                return
                        }
                    } catch {
                        print("Failed to check for existing city: \(error.localizedDescription)")
                        alertTitle = "Fetch Error"
                        alertMessage = "Failed to check for duplicate city: \(error.localizedDescription)"
                        showAlert = true
                        return
                    }
                    
                    modelContext.insert(city)
                    
                    do {
                            try modelContext.save()
                        print("Successfully saved city: \(city.name)")
                    } catch {
                        print("Failed to save city \(city.name): \(error.localizedDescription)")
                        alertTitle = "Save Error"
                        alertMessage = "Failed to save the city: \(error.localizedDescription)"
                        showAlert = true
                    }
                }
            )
        }
        .padding(.vertical, 8)
        .background(Color("Background"))
    }
    private func unsaveBucket(name: String, latitude: Double?, longitude: Double?) {
        print("Attempting to save: \(name)")
            print("Latitude: \(latitude ?? -999.0), Longitude: \(longitude ?? -999.0)") // Print values
        
        guard let latitude = latitude, let longitude = longitude else {
            alertTitle = "Failed Insertion"
            alertMessage = "Invalid city coordinates"
            showAlert = true
            return
        }
        
        let fetchDescriptor = FetchDescriptor<City>(
                predicate: #Predicate { $0.name == name && $0.latitude == latitude && $0.longitude == longitude })

        do {
            let citiesToUpdate = try modelContext.fetch(fetchDescriptor)
            if let cityToUpdate = citiesToUpdate.first {
                modelContext.delete(cityToUpdate)
                    try modelContext.save()
                    print("Toggled bucket list.")
                    return
            }
        } catch {
            print("Failed to toggle bucket list: \(error.localizedDescription)")
            alertTitle = "Fetch Error"
            alertMessage = "Failed to toggle bucket list: \(error.localizedDescription)"
            showAlert = true
            return
        }
    }
    private func saveCity(name: String, latitude: Double?, longitude: Double?, country: String, admin: String, bucket: Bool, visit: Bool) {
        print("Attempting to save: \(name)")
            print("Latitude: \(latitude ?? -999.0), Longitude: \(longitude ?? -999.0)") // Print values
        
        guard let latitude = latitude, let longitude = longitude else {
            alertTitle = "Failed Insertion"
            alertMessage = "Invalid city coordinates"
            showAlert = true
            return
        }
        
        let fetchDescriptor = FetchDescriptor<City>(
                predicate: #Predicate { $0.name == name && $0.latitude == latitude && $0.longitude == longitude })

        do {
            let existingCities = try modelContext.fetch(fetchDescriptor)
            if let existingCity = existingCities.first {
                    existingCity.bucketList = false
                    existingCity.isVisited = true

                    try modelContext.save()
                    print("Updated existing city \(name) to visited.")
                    return
            }
        } catch {
            print("Failed to check for existing city: \(error.localizedDescription)")
            alertTitle = "Fetch Error"
            alertMessage = "Failed to check for duplicate city: \(error.localizedDescription)"
            showAlert = true
            return
        }
        
        let newCity = City(name: name, latitude: latitude, longitude: longitude, bucketList: bucket, isVisited: visit, country: country, admin: admin)
        modelContext.insert(newCity)
        
        do {
                try modelContext.save()
                print("Successfully saved city: \(name)")
        } catch {
            print("Failed to save city \(name): \(error.localizedDescription)")
            alertTitle = "Save Error"
            alertMessage = "Failed to save the city: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

#Preview("Search List Member") {
    SearchListMember(result: SearchResult(title: "Vancouver", subtitle: "British Columbia, Canada", latitude: 100, longitude: 100, population: 10000, country: "Canada", admin: "British Columbia"))
}
