//
//  NotesEditorView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-17.
//
import SwiftData
import SwiftUI

struct NotesEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let city: City
    @State private var notes: String
    
    init(city: City) {
        self.city = city
        self._notes = State(initialValue: city.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            TextEditor(text: $notes)
                .padding()
                .navigationTitle("Edit Notes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveNotes()
                        }
                        .fontWeight(.semibold)
                    }
                }
        }
        .background(Color("Background"))
    }
    
    private func saveNotes() {
        city.notes = notes.isEmpty ? nil : notes
        do {
            try modelContext.save()
        } catch {
            print("Error saving notes: \(error)")
        }
        dismiss()
    }
}
