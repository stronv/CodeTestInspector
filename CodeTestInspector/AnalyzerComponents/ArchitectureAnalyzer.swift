//
//  ArchitectureAnalyzer.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 20.04.2025.
//

import Foundation

protocol IComponentIdentifier: AnyObject {
    func identifyComponentType(for className: String) -> MVVMComponent
}


// MARK: - Architecture Component Type

enum MVVMComponent {
    case model
    case view
    case viewModel
    case unknown
}

// MARK: - ArchitectureAnalyzer

final class ArchitectureAnalyzer: IComponentIdentifier {
    let directoryURL: URL
    let graph = DependencyGraph()
    let parser = CodeParser()
    
    init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }
    
    func analyze() throws -> [Violation] {
        let swiftFiles = try collectSwiftFiles(in: directoryURL)

        var sourceFiles: [String: String] = [:]

        for file in swiftFiles {
            do {
                let source = try String(contentsOf: file)
                let partialGraph = try parser.buildDependencyGraph(from: source)
                mergeGraphs(from: partialGraph)
                sourceFiles[file.path] = source
            } catch {
                print("⚠️ Failed to parse: \(file.lastPathComponent): \(error)")
            }
        }

        return checkForMVVMViolations(sourceFiles: sourceFiles)
    }
    
    // MARK: - IComponentIdentifier
    
    func identifyComponentType(for className: String) -> MVVMComponent {
        if className.lowercased().contains("viewmodel") {
            return .viewModel
        } else if className.lowercased().contains("view") {
            return .view
        } else if className.lowercased().contains("model") {
            return .model
        }
        return .unknown
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
    
    func checkForMVVMViolations(sourceFiles: [String: String]) -> [Violation] {
        var violations: [Violation] = []
        var seenViolations = Set<String>()

        for (origin, targets) in graph.adjacencyList {
            let originType = identifyComponentType(for: origin)

            for target in targets {
                let targetType = identifyComponentType(for: target)
                let key = "\(origin)->\(target)"

                if (originType == .viewModel && targetType == .view) ||
                    (originType == .view && targetType == .model),
                    !seenViolations.contains(key) {

                    seenViolations.insert(key)

                    if let (filePath, source) = sourceFiles.first(where: { $0.value.contains(origin) }) {
                        let lines = source.components(separatedBy: .newlines)
                        let matchLineIndex = lines.firstIndex(where: { $0.contains(origin) && $0.contains(target) }) ??
                                             lines.firstIndex(where: { $0.contains(origin) }) ??
                                             0

                        let contextRange = max(0, matchLineIndex - 2)...min(lines.count - 1, matchLineIndex + 2)
                        let snippet = lines[contextRange].joined(separator: "\n")

                        let recommendation = originType == .viewModel
                            ? RecomendationForMVVM.vmRecomendation
                            : RecomendationForMVVM.viewRecomendation

                        violations.append(
                            Violation(
                                className: origin,
                                issue: "\(origin) зависит от \(target)",
                                recommendation: recommendation,
                                filePath: filePath,
                                codeSnippet: snippet,
                                lineNumber: matchLineIndex + 1
                            )
                        )
                    } else {
                        violations.append(
                            Violation(
                                className: origin,
                                issue: "\(origin) зависит от \(target)",
                                recommendation: originType == .viewModel
                                    ? RecomendationForMVVM.vmRecomendation
                                    : RecomendationForMVVM.viewRecomendation,
                                filePath: "Неизвестно",
                                codeSnippet: "// Не удалось найти фрагмент",
                                lineNumber: 0
                            )
                        )
                    }
                }
            }
        }
        return violations
    }
}

// MARK: - Constants

private extension ArchitectureAnalyzer {
    enum RecomendationForMVVM {
        static let viewRecomendation: String = "Move logic to ViewModel. View should not directly depend on Model."
        static let vmRecomendation: String = "Refactor to remove dependency on the View. Use bindings, delegate, or observable pattern."
    }
}
