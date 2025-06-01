//
//  ArchitectureAnalyzerViewModel.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 28.05.2025.
//

import Foundation

protocol ArchitectureAnalyzerViewModelProtocol: AnyObject {
    func analyze()
}

final class ArchitectureAnalyzerViewModel: ObservableObject {
    @Published var selectedPath: URL?
    @Published var violations: [ArchitectureViolation] = []
    @Published var ruleManager = RuleManager()

    private let analysisService: ArchitectureAnalysisServiceProtocol

    init(analysisService: ArchitectureAnalysisServiceProtocol = ArchitectureAnalysisService()) {
        self.analysisService = analysisService
    }

    var parsedRules: Set<DependencyRule> {
        ruleManager.parsedRules
    }

    func analyze() {
        guard let path = selectedPath else { return }
        violations = analysisService.analyze(path: path, rules: parsedRules)
    }
}
