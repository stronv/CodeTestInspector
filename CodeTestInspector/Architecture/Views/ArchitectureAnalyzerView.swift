//
//  ArchitectureAnalyzerView.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 28.05.2025.
//

import Foundation
import SwiftUI

struct ArchitectureAnalyzerView: View {
    @ObservedObject var viewModel: ArchitectureAnalyzerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("Выбрать проект") {
                let panel = NSOpenPanel()
                panel.canChooseDirectories = true
                panel.canChooseFiles = false
                panel.begin { response in
                    guard response == .OK, let url = panel.url else { return }
                    viewModel.selectedPath = url
                }
            }

            if let path = viewModel.selectedPath {
                Text("📂 Путь к проекту: \(path.path)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Button("Анализировать") {
                viewModel.analyze()
            }
            .disabled(viewModel.parsedRules.isEmpty || viewModel.selectedPath == nil)

            if viewModel.violations.isEmpty && viewModel.selectedPath != nil {
                Text("✅ Нарушений не найдено")
                    .foregroundColor(.green)
                    .font(.caption)
            } else if !viewModel.violations.isEmpty {
                Divider()
                Text("🚫 Нарушения:")
                    .font(.subheadline)
                    .bold()
                ForEach(viewModel.violations, id: \.fromClass) { v in
                    Text("\(v.fromClass) (\(v.fromComponent)) → \(v.toClass) (\(v.toComponent))")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            Spacer()
        }
        .padding()
    }
}
