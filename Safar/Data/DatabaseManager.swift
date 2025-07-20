//
//  DatabaseManager.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-04.
//

import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()

    private var citiesDB: Connection?
    private var countriesDB: Connection?

    private init() {
        openDatabases()
    }

    private func openDatabases() {
        if let citiesPath = Bundle.main.path(forResource: "cities", ofType: "sqlite"),
           let countriesPath = Bundle.main.path(forResource: "countries", ofType: "sqlite") {
            do {
                citiesDB = try Connection(citiesPath, readonly: true)
                countriesDB = try Connection(countriesPath, readonly: true)
            } catch {
                print("Failed to open database: \(error)")
            }
        }
    }    
    
    private func normalizeForSearch(_ text: String) -> String {
           return text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
       }
    
    func searchCities(query: String) -> [SearchResult] {
        guard let db = citiesDB else { return [] }
        let normalizedQuery = normalizeForSearch(query)

        var results: [SearchResult] = []
        let citiesTable = Table("cities")
        let name = Expression<String?>("name")
        let admin1 = Expression<String?>("admin1")
        let country = Expression<String?>("country")
        let latitude = Expression<Double>("latitude")
        let longitude = Expression<Double>("longitude")
        let population = Expression<Int>("population")
        let plain_name = Expression<String>("plain_name")

        do {
            let queryResults = try db.prepare(
                citiesTable.filter(plain_name.like("%\(normalizedQuery)%")).limit(50)
            )
            for row in queryResults {
                if let cityName = row[name] {
                    let admin = row[admin1] ?? ""
                    let countryName = row[country] ?? ""
                    let subtitle = [admin, countryName].filter { !$0.isEmpty }.joined(separator: ", ")
                    let lat = row[latitude]
                    let long = row[longitude]
                    let pop = row[population]

                    results.append(SearchResult(title: cityName, subtitle: subtitle, latitude: lat, longitude: long, population: pop, country: countryName, admin: admin))
                }
            }
        } catch {
            print("City search error: \(error)")
        }

        return results
    }


    func searchCountries(query: String) -> [String] {
        guard let db = countriesDB else { return [] }

        var results: [String] = []
        let countriesTable = Table("countries")
        let name = Expression<String?>("name")

        do {
            let queryResults = try db.prepare(
                countriesTable.filter(name.like("%\(query)%")).limit(50)
            )
            for row in queryResults {
                if let countryName = row[name] {
                    results.append(countryName)
                }
            }
        } catch {
            print("Country search error: \(error)")
        }

        return results
    }
    
    func getCountryAndContinent(forCountry country: String) -> (country: String?, continent: String?) { 
        guard let db = countriesDB else { return (nil, nil) }

        let countriesTable = Table("countries")
        let nameCol = Expression<String?>("name")
        let continentCol = Expression<String?>("continent")

        do {
            if let row = try db.pluck(countriesTable.filter(nameCol == country)) {
                return (row[nameCol], row[continentCol])
            }
        } catch {
            print("Failed country lookup: \(error)")
        }
        return (nil, nil)
    }

}
