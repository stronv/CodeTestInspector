//
//  ArchitectureAnalysisService.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 28.05.2025.
//

import Foundation

protocol ArchitectureAnalysisServiceProtocol: AnyObject {
    func analyze(path: URL, rules: Set<DependencyRule>) -> [ArchitectureViolation]
}

final class ArchitectureAnalysisService: ArchitectureAnalysisServiceProtocol {
    private let engine: AnalyzerEngineProtocol

    init(engine: AnalyzerEngineProtocol = AnalyzerEngine()) {
        self.engine = engine
    }

    func analyze(path: URL, rules: Set<DependencyRule>) -> [ArchitectureViolation] {
        let entities = engine.collectEntities(at: path)
        return analyzeArchitecture(entities: entities, rules: rules)
    }
}

private extension ArchitectureAnalysisService {
    func analyzeArchitecture(
        entities: [ParsedEntity],
        rules: Set<DependencyRule>
    ) -> [ArchitectureViolation] {
        var violations: [ArchitectureViolation] = []

        var componentTypes: [String: String] = [:]
        for entity in entities {
            let lower = entity.name.lowercased()
            if let matched = rules.flatMap({ [$0.from, $0.to] }).first(where: { lower.contains($0) }) {
                componentTypes[entity.name] = matched
            }
        }

        for origin in componentTypes {
            for target in componentTypes {
                guard origin.key != target.key else { continue }
                let rule = DependencyRule(from: origin.value, to: target.value)
                if !rules.contains(rule) {
                    violations.append(
                        ArchitectureViolation(
                            fromClass: origin.key,
                            fromComponent: origin.value,
                            toClass: target.key,
                            toComponent: target.value,
                            filePath: entities.first(where: { $0.name == origin.key })?.filePath ?? "?"
                        )
                    )
                }
            }
        }
        return violations
    }
}
