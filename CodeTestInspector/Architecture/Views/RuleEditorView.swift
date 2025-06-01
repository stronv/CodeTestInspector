//
//  RuleEditorView.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 26.05.2025.
//

import SwiftUI

struct RuleEditorView: View {
    @ObservedObject var viewModel: ArchitectureAnalyzerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Введите правила зависимостей (формат: A - B):")
                .font(.headline)

            TextEditor(text: $viewModel.ruleManager.rawRules)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 200)
                .border(Color.gray)

            Button("Применить правила") {
                viewModel.ruleManager.parseRules()
            }
            .buttonStyle(.borderedProminent)

            if !viewModel.ruleManager.parsedRules.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("✅ Разобранные правила:")
                        .font(.subheadline)
                        .bold()
                    ForEach(Array(viewModel.ruleManager.parsedRules), id: \.self) { rule in
                        Text("\(rule.from.capitalized) → \(rule.to.capitalized)")
                            .font(.caption)
                    }
                }
            }
            Spacer()
        }
        .padding()
    }
}
