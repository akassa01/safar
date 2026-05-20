//
//  ReportView.swift
//  Safar
//
//  Sheet for reporting a post, comment, or user. Parameterized by ReportType
//  so the same view handles all three surfaces.
//

import SwiftUI

struct ReportView: View {
    let type: ReportType
    let targetId: String
    let targetDisplayName: String
    @Environment(\.dismiss) private var dismiss

    @State private var selectedReason: ReportReason?
    @State private var details = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Why are you reporting this \(type.displayName)?") {
                    ForEach(ReportReason.allCases) { reason in
                        Button {
                            selectedReason = reason
                        } label: {
                            HStack {
                                Text(reason.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }

                Section("Additional details (optional)") {
                    TextField("Describe the issue...", text: $details, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("Report \(targetDisplayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Submit") {
                        submitReport()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedReason == nil || isSubmitting)
                }
            }
            .alert("Report Submitted", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Thank you. We'll review this shortly.")
            }
            .alert("Submission Failed", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text("Something went wrong. Please try again.")
            }
        }
    }

    private func submitReport() {
        guard let reason = selectedReason else { return }
        isSubmitting = true
        Task {
            do {
                try await DatabaseManager.shared.submitReport(
                    type: type,
                    targetId: targetId,
                    reason: reason,
                    details: details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? nil
                        : details.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                showSuccess = true
            } catch {
                showError = true
            }
            isSubmitting = false
        }
    }
}
