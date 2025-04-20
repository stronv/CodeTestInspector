//
//  ContentView.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 20.04.2025.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var folderPath: String = ""
    @State private var analysisResult: String = ""
    @State private var selectedAnalysis: AnalysisType = .testability
    @State private var architectureViolations: [Violation] = []

    enum AnalysisType: String, CaseIterable, Identifiable {
        case testability = "Testability"
        case architecture = "MVVM Architecture"

        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("🧪 Code Analyzer")
                .font(.largeTitle)
                .bold()

            Picker("Тип анализа", selection: $selectedAnalysis) {
                ForEach(AnalysisType.allCases) { analysis in
                    Text(analysis.rawValue).tag(analysis)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            HStack {
                TextField("Выберите путь к проекту", text: $folderPath)
                    .frame(maxWidth: .infinity)
                Button("Обзор") {
                    selectFolder()
                }
            }

            Button("Анализировать") {
                runSelectedAnalysis()
            }
            .disabled(folderPath.isEmpty)

            Divider()

            ScrollView {
                if selectedAnalysis == .testability {
                    Text(analysisResult)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                } else {
                    if architectureViolations.isEmpty {
                        Text("✅ No MVVM violations found.")
                            .foregroundColor(.green)
                            .padding()
                    } else {
                        VStack(alignment: .leading) {
                            ForEach(architectureViolations) { violation in
                                ViolationView(violation: violation)
                                    .padding(.bottom, 10)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }

            Spacer()
        }
        .padding()
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            if let url = panel.url {
                folderPath = url.path
            }
        }
    }

    private func runSelectedAnalysis() {
        switch selectedAnalysis {
        case .testability:
            analysisResult = Analyzer.analyze(projectPath: folderPath)
            architectureViolations = []
        case .architecture:
            do {
                let analyzer = ArchitectureAnalyzer(directoryURL: URL(fileURLWithPath: folderPath))
                let violations = try analyzer.analyze()
                architectureViolations = violations
                analysisResult = ""
            } catch {
                analysisResult = "❌ Ошибка анализа архитектуры: \(error)"
                architectureViolations = []
            }
        }
    }
}
