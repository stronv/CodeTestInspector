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
    @State private var isAnalyzing = false
    @State private var isRuleEditorDirty: Bool = false
    
    @State private var architectureJSON: String = """
    {
      "name": "Custom MVVM",
      "rules": [
        { "component": "View", "allowedDependencies": ["ViewModel"] },
        { "component": "ViewModel", "allowedDependencies": ["Model"] },
        { "component": "Model", "allowedDependencies": [] }
      ]
    }
    """

    @State private var parsedRules = ArchitectureRules(name: "Custom MVVM", rules: [])
    @State private var parsingError: String? = nil
    
    private let orderedMetricKeys = [
        "Total Classes",
        "Total Dependencies",
        "Coupling",
        "Cohesion",
        "Cyclomatic Complexity",
        "Maintainability Index"
    ]

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

            Button("🔍 Анализировать") {
                runSelectedAnalysis()
            }
            .disabled(folderPath.isEmpty || isAnalyzing)

            Divider()
            
            if selectedAnalysis == .architecture {
                ArchitectureRuleEditorView(
                    jsonText: $architectureJSON,
                    parsedRules: $parsedRules,
                    errorMessage: $parsingError,
                    isDirty: $isRuleEditorDirty
                )
            }
            
            if isAnalyzing {
                ProgressView("Анализируем...")
                    .padding()
            }

            ScrollView {
                if selectedAnalysis == .testability {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(orderedMetricKeys, id: \.self) { key in
                            if let value = extractValue(for: key, from: analysisResult) {
                                HStack {
                                    Text("\(key):")
                                        .bold()
                                    Spacer()
                                    Text(value)
                                }
                            }
                        }
                    }
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
        isAnalyzing = true

        DispatchQueue.global(qos: .userInitiated).async {
            switch selectedAnalysis {
            case .testability:
                do {
                    let graph = try TestabilityAnalyzer.analyze(projectPath: folderPath)
                    let metricsCalculator = TestabilityMetricsCalculator(graph: graph)
                    let metrics = metricsCalculator.calculateMetrics()

                    DispatchQueue.main.async {
                        self.analysisResult = metrics.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
                        self.architectureViolations = []
                        self.isAnalyzing = false
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.analysisResult = "❌ Ошибка анализа тестируемости: \(error)"
                        self.architectureViolations = []
                        self.isAnalyzing = false
                    }
                }

            case .architecture:
                do {
                    let analyzer = ArchitectureAnalyzer(
                        directoryURL: URL(fileURLWithPath: folderPath),
                        rules: parsedRules
                    )
                    let violations = try analyzer.analyze()
                    DispatchQueue.main.async {
                        self.architectureViolations = violations
                        self.analysisResult = ""
                        self.isAnalyzing = false
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.analysisResult = "❌ Ошибка анализа архитектуры: \(error)"
                        self.architectureViolations = []
                        self.isAnalyzing = false
                    }
                }
            }
        }
    }
}

private extension ContentView {
    private func splitMetricLine(_ line: String) -> (String, String)? {
        let components = line.components(separatedBy: ":")
        guard components.count >= 2 else { return nil }
        let key = components[0]
        let value = components[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
        return (key, value)
    }
    private func extractValue(for key: String, from analysisResult: String) -> String? {
        let lines = analysisResult.components(separatedBy: "\n")
        for line in lines {
            if line.starts(with: key + ":") {
                let components = line.components(separatedBy: ":")
                if components.count >= 2 {
                    return components[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
                }
            }
        }
        return nil
    }


}
