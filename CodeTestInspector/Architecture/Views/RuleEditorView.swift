//
//  RuleEditorView.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 26.05.2025.
//

import SwiftUI

struct RulesSection: View {
    @ObservedObject var ruleManager: RuleManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Введите правила зависимостей (формат: A - B):")
                .font(.headline)
            
            // Белый фон для редактора, рамка
            ZStack {
                Color.white
                TextEditor(text: $ruleManager.rawRules)
                    .font(.system(.body, design: .monospaced))
                    .padding(4)
            }
            .frame(minHeight: 200)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray))

            HStack {
                Button("Применить правила") {
                    ruleManager.parseRules()
                    print("Array - \(Array(ruleManager.parsedRules))")
                }
                .buttonStyle(.borderedProminent)

                // По желанию: при провальной валидации показываем Alert — дальше
            }

            if !ruleManager.parsedRules.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("✅ Разобранные правила:")
                        .font(.subheadline)
                        .bold()
                    ForEach(Array(ruleManager.parsedRules), id: \.self) { rule in
                        Text("\(rule.from.capitalized) → \(rule.to.capitalized)")
                            .font(.caption)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}
