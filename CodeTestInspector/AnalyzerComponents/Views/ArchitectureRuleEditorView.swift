//
//  ArchitectureRuleEditorView.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 20.04.2025.
//

import Foundation
import SwiftUI

struct ArchitectureRuleEditorView: View {
    @Binding var jsonText: String
    @Binding var parsedRules: ArchitectureRules
    @Binding var errorMessage: String?
    @Binding var isDirty: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🧱 Архитектурные правила (JSON):")
                .font(.headline)

            TextEditor(text: $jsonText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 150)
                .border(Color.gray)
                .onChange(of: jsonText) {
                    isDirty = true
                }

            Button("✅ Применить правила") {
                applyArchitectureJSON()
            }
            .disabled(!isDirty) //

            if let error = errorMessage {
                Text("⚠️ 1 \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }

    private func applyArchitectureJSON() {
        do {
            let data = Data(jsonText.utf8)
            let decoded = try JSONDecoder().decode(ArchitectureRules.self, from: data)
            parsedRules = decoded
            errorMessage = nil
            isDirty = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
