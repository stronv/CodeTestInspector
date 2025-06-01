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

        // 1) entityName → filePath
        let filePathForName: [String: String] = {
            var dict = [String: String]()
            for e in entities {
                dict[e.name] = e.filePath
            }
            return dict
        }()

        // 2) Построим componentTypes
        let componentTypes: [String: String] = {
            let pairs: [(String, String)] = entities.compactMap { entity in
                let lowerName = entity.name.lowercased()
                if let matchRule = rules.first(where: {
                    lowerName.hasSuffix($0.from.lowercased()) ||
                    lowerName.hasSuffix($0.to.lowercased())
                }) {
                    let component = lowerName.hasSuffix(matchRule.from.lowercased())
                        ? matchRule.from.lowercased()
                        : matchRule.to.lowercased()
                    return (entity.name, component)
                }
                return nil
            }
            return Dictionary(uniqueKeysWithValues: pairs)
        }()

        // 3) Проверка связей
        for (originName, originComponent) in componentTypes {
            for (targetName, targetComponent) in componentTypes {
                guard originName != targetName else { continue }

                let currentRule = DependencyRule(from: originComponent, to: targetComponent)
                if !rules.contains(currentRule) {
                    guard let originFile = filePathForName[originName] else {
                        continue
                    }
                    // Принты для отладки
                    print("Ищем violation: origin=\(originName) target=\(targetName) в файле \(originFile)")

                    let (foundLine, snippet) = findFirstOccurrence(
                        of: targetName,
                        inFileAt: originFile
                    )

                    let violation = ArchitectureViolation(
                        fromClass: originName,
                        fromComponent: originComponent,
                        toClass: targetName,
                        toComponent: targetComponent,
                        filePath: originFile,
                        lineNumber: foundLine,
                        snippetLines: snippet
                    )
                    violations.append(violation)
                }
            }
        }

        return violations
    }

    func findFirstOccurrence(
        of targetName: String,
        inFileAt path: String
    ) -> (lineNumber: Int, snippetLines: [(Int, String)]) {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return (1, [(1, "// Не удалось прочитать файл")])
        }
        let lines = content.components(separatedBy: .newlines)
        let needle = targetName.lowercased() + "("  // например, "userview("

        // Сначала ищем инициализацию с "UserView("
        for (index, line) in lines.enumerated() {
            let lowerLine = line.lowercased()
            if lowerLine.contains(needle) {
                let matchedLineIndex = index + 1
                let start = max(0, index - 2)
                let end = min(lines.count - 1, index + 2)
                var snippet: [(Int, String)] = []
                for i in start...end {
                    snippet.append((i + 1, lines[i]))
                }
                return (matchedLineIndex, snippet)
            }
        }
        // Если не нашли через "UserView(", ищем просто "userview"
        for (index, line) in lines.enumerated() {
            if line.lowercased().contains(targetName.lowercased()) {
                let matchedLineIndex = index + 1
                let start = max(0, index - 2)
                let end = min(lines.count - 1, index + 2)
                var snippet: [(Int, String)] = []
                for i in start...end {
                    snippet.append((i + 1, lines[i]))
                }
                return (matchedLineIndex, snippet)
            }
        }
        // Не нашли упоминания
        return (
            1,
            [(1, "// Не удалось найти упоминание “\(targetName)”")]
        )
    }
}

