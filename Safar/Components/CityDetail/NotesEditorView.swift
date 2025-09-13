//
//  NotesEditorView.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-17.
//

import SwiftUI

struct NotesEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = UserCitiesViewModel()
    
    let city: City
    @State private var notes: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    init(city: City) {
        self.city = city
        self._notes = State(initialValue: city.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                TextEditor(text: $notes)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
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
                    .disabled(isLoading)
                }
            }
        }
        .background(Color("Background"))
        .task {
            await viewModel.initializeWithCurrentUser()
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
    }
    
    private func saveNotes() {
        guard let userId = viewModel.currentUserId else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await DatabaseManager.shared.updateUserCityNotes(
                    userId: userId,
                    cityId: city.id,
                    notes: notes.isEmpty ? "" : notes
                )
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to save notes: \(error.localizedDescription)"
                }
            }
        }
    }
}
