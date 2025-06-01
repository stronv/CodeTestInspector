//
//  ArchitectureAnalyzerView.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 28.05.2025.
//

import Foundation
import SwiftUI

struct PathAndAnalyzeSection: View {
    @ObservedObject var viewModel: ArchitectureAnalyzerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Обзор…") {
                let panel = NSOpenPanel()
                panel.canChooseDirectories = true
                panel.canChooseFiles = false
                panel.begin { response in
                    guard response == .OK, let url = panel.url else { return }
                    viewModel.selectedPath = url
                }
            }
            .buttonStyle(.bordered) // более компактная кнопка

            if let path = viewModel.selectedPath {
                HStack(spacing: 4) {
                    Image(systemName: "folder")
                        .foregroundColor(.gray)
                    Text(path.path)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                // Чтобы строка не была слишком длинной, можно обрезать по середине
            }

            Button("🔍 Анализировать") {
                viewModel.analyze()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.ruleManager.parsedRules.isEmpty || viewModel.selectedPath == nil)
        }
    }
}
