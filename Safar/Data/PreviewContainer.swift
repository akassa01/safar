//
//  PreviewContainer.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-05.
//

import Foundation
import SwiftData

struct PreviewContainer {
    let container: ModelContainer!
    init (_ types: [any PersistentModel.Type], isStoredInMemoryOnly: Bool = true) {
        let schema = Schema(types)
        let config = ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
        self.container = try! ModelContainer(for: schema, configurations: [config])
    }
    
    func add(items: [any PersistentModel]) {
        Task {@MainActor in
            items.forEach { container.mainContext.insert($0) }
        }
    }
}
