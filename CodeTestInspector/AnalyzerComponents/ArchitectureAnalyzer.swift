//
//  ArchitectureAnalyzer.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 20.04.2025.
//

import Foundation

protocol IComponentIdentifier: AnyObject {
    func identifyComponentType(for className: String) -> String
}

// MARK: - ArchitectureAnalyzer

final class ArchitectureAnalyzer: IComponentIdentifier {
    let directoryURL: URL
    let graph = DependencyGraph()
    let parser = CodeParser()
    let rules: ArchitectureRules
    
    init(directoryURL: URL, rules: ArchitectureRules) {
        self.directoryURL = directoryURL
        self.rules = rules
    }
    
    func analyze() throws -> [Violation] {
        graph.adjacencyList.removeAll()

        let swiftFiles = try collectSwiftFiles(in: directoryURL)
        var sourceFiles: [String: String] = [:]
        var classToFile: [String: String] = [:]

        for file in swiftFiles {
            do {
                let source = try String(contentsOf: file)
                sourceFiles[file.path] = source

                if let declaredClass = extractTopLevelClassName(from: source) {
                    classToFile[declaredClass] = file.path
                }

                let partialGraph = try parser.buildDependencyGraph(from: source)
                mergeGraphs(from: partialGraph)

            } catch {
                print("⚠️ Failed to parse: \(file.lastPathComponent): \(error)")
            }
        }

        return checkForViolations(sourceFiles: sourceFiles, classToFile: classToFile)
    }

    
    // MARK: - IComponentIdentifier
    
    func identifyComponentType(for className: String) -> String {
        let lowercased = className.lowercased()

        if lowercased.contains("viewmodel") {
            return "ViewModel"
        } else if lowercased.contains("view") {
            return "View"
        } else if lowercased.contains("model") {
            return "Model"
        } else {
            return "Unknown"
        }
    }
    
    func extractTopLevelClassName(from source: String) -> String? {
        let lines = source.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("final class") || trimmed.hasPrefix("class ") {
                let components = trimmed.components(separatedBy: .whitespaces)
                if let classIndex = components.firstIndex(where: { $0 == "class" }),
                   classIndex + 1 < components.count {
                    return components[classIndex + 1]
                }
            }
        }
        return nil
    }
}

// MARK: - Private methods

private extension ArchitectureAnalyzer {
    func collectSwiftFiles(in directory: URL) throws -> [URL] {
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey]
        let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: resourceKeys)!

        var swiftFiles: [URL] = []

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "swift" {
                swiftFiles.append(fileURL)
            }
        }

        return swiftFiles
    }
    
    func mergeGraphs(from partialGraph: DependencyGraph) {
        for (origin, targets) in partialGraph.adjacencyList {
            for target in targets {
                graph.addDependency(from: origin, to: target)
            }
        }
    }
    
    func checkForViolations(
        sourceFiles: [String: String],
        classToFile: [String: String]
    ) -> [Violation] {
        var violations: [Violation] = []
        var seenViolations = Set<String>()

        for (origin, targets) in graph.adjacencyList {
            let originType = identifyComponentType(for: origin)

            guard let originRule = rules.rules.first(where: { $0.component == originType }) else {
                continue
            }

            for target in targets {
                let targetType = identifyComponentType(for: target)
                let key = "\(origin)->\(target)"

                if !originRule.allowedDependencies.contains(targetType),
                   !seenViolations.contains(key) {

                    seenViolations.insert(key)

                    let filePath = classToFile[origin] ?? "?"
                    let source = sourceFiles[filePath] ?? ""
                    let (snippet, line) = extractSnippet(from: source, for: target)

                    violations.append(
                        Violation(
                            className: origin,
                            issue: "\(originType) '\(origin)' зависит от \(targetType) '\(target)', что нарушает архитектуру '\(rules.name)'",
                            recommendation: "\(originType) не должен напрямую зависеть от \(targetType) по правилам '\(rules.name)'.",
                            filePath: filePath,
                            codeSnippet: snippet,
                            lineNumber: line
                        )
                    )
                }
            }
        }

        return violations
    }
    
    func extractSnippet(from source: String, for className: String, context: Int = 2) -> (String, Int) {
        let lines = source.components(separatedBy: .newlines)

        if let index = lines.firstIndex(where: { $0.contains(className) }) {
            let start = max(0, index - context)
            let end = min(lines.count - 1, index + context)
            let snippet = lines[start...end].joined(separator: "\n")
            return (snippet, index + 1)
        }

        return ("// Не удалось найти фрагмент с \(className)", 0)
    }
}

// MARK: - Constants

private extension ArchitectureAnalyzer {
    enum RecomendationForMVVM {
        static let viewRecomendation: String = "Move logic to ViewModel. View should not directly depend on Model."
        static let vmRecomendation: String = "Refactor to remove dependency on the View. Use bindings, delegate, or observable pattern."
    }
}
