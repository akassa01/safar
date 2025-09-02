//
//  safarApp.swift
//  safar
//
//  Created by Arman Kassam on 2025-06-30.
//

import SwiftUI
import SwiftData

@main
struct safarApp: App {
    var body: some Scene {
        WindowGroup {
            AppView()
        }
        .modelContainer(for: [City.self])
        
    }
}
