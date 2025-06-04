//
//  MetricsAnalysisService.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 01.06.2025.
//

import Foundation
import SwiftSyntax
import SwiftParser

protocol MetricsAnalysisServiceProtocol {
    func computeMetrics(at path: URL) -> MetricsResult
}

final class MetricsAnalysisService: MetricsAnalysisServiceProtocol {
    private let scanner: ProjectScannerProtocol

    init(scanner: ProjectScannerProtocol = ProjectScanner()) {
        self.scanner = scanner
    }

    func computeMetrics(at path: URL) -> MetricsResult {
        // 1) Сканируем все .swift-файлы
        let swiftFiles = scanner.scan(at: path)

        // 2) Сначала собираем все имена entity
        let allNames = collectAllNames(from: swiftFiles)

        // 3) Обрабатываем каждый файл: собираем CC, количество строк и зависимости,
        //    аккумулируем результаты
        var totalCyclomatic = 0
        var totalLinesOfCode = 0
        var totalFunctions = 0

        var adjacencyList: [String: Set<String>] = [:]
        var incomingCount: [String: Int] = [:]
        var allEntities: Set<String> = []
        var totalOutgoingDependencies = 0

        for fileURL in swiftFiles {
            guard let fileMetrics = processFile(
                fileURL: fileURL,
                allNames: allNames
            ) else {
                continue
            }

            // Аккумулируем CC и функции
            totalCyclomatic += fileMetrics.cyclomaticSum
            totalFunctions += fileMetrics.functionCount
            totalLinesOfCode += fileMetrics.linesOfCode

            // Аккумулируем зависимости из этого файла
            for entity in fileMetrics.entities {
                let origin = entity.name
                allEntities.insert(origin)

                let deps = entity.dependencies
                adjacencyList[origin] = deps
                totalOutgoingDependencies += deps.count

                for target in deps {
                    incomingCount[target, default: 0] += 1
                    allEntities.insert(target)
                }
                // Гарантируем хотя бы 0 входящих для origin
                incomingCount[origin] = incomingCount[origin] ?? 0
            }
        }

        // 4) Формируем финальный MetricsResult
        return buildResult(
            totalCyclomatic: totalCyclomatic,
            totalFunctions: totalFunctions,
            totalLinesOfCode: totalLinesOfCode,
            allEntities: allEntities,
            adjacencyList: adjacencyList,
            incomingCount: incomingCount,
            totalOutgoingDependencies: totalOutgoingDependencies
        )
    }
}

// MARK: — Private methods
private extension MetricsAnalysisService {
    /// 1) Первый проход: обходит каждый файл и собирает все имена классов/структур/протоколов
    func collectAllNames(from files: [URL]) -> Set<String> {
        var names: Set<String> = []

        for fileURL in files {
            guard let source = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            let tree = Parser.parse(source: source)

            let nameCollector = NameCollector(viewMode: .all)
            nameCollector.walk(tree)

            names.formUnion(nameCollector.names)
        }

        return names
    }

    /// 2) Для одного файла вычисляет:
    ///    - сумма CC всех функций (cyclomaticSum)
    ///    - число функций (functionCount)
    ///    - число строк (linesOfCode)
    ///    - зависимости ParsedMetricEntity (entities)
    func processFile(
        fileURL: URL,
        allNames: Set<String>
    ) -> (cyclomaticSum: Int, functionCount: Int, linesOfCode: Int, entities: [ParsedMetricEntity])? {
        guard let source = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return nil
        }
        let syntaxTree = Parser.parse(source: source)

        // 2.1) Считаем строки кода
        let linesOfCode = source.components(separatedBy: .newlines).count

        // 2.2) Собираем Cyclomatic Complexity
        let filePathString = fileURL.path
        let locationConverter = SourceLocationConverter(
            fileName: filePathString,
            tree: syntaxTree
        )
        let cycloVisitor = CyclomaticComplexityVisitor(
            filePath: filePathString,
            locationConverter: locationConverter
        )
        cycloVisitor.walk(syntaxTree)

        let cyclomaticSum = cycloVisitor.functionComplexities.reduce(0) { $0 + $1.complexity }
        let functionCount = cycloVisitor.functionComplexities.count

        // 2.3) Собираем зависимости через DependencyCollector
        let depCollector = DependencyCollector(
            allNames: allNames,
            filePath: filePathString
        )
        depCollector.walk(syntaxTree)
        let entities = depCollector.entities

        return (cyclomaticSum, functionCount, linesOfCode, entities)
    }

    /// 3) Строит финальный MetricsResult на основании аккумулированных данных
    func buildResult(
        totalCyclomatic: Int,
        totalFunctions: Int,
        totalLinesOfCode: Int,
        allEntities: Set<String>,
        adjacencyList: [String: Set<String>],
        incomingCount: [String: Int],
        totalOutgoingDependencies: Int
    ) -> MetricsResult {
        var result = MetricsResult()

        // Cyclomatic Complexity
        result.totalCyclomatic = totalCyclomatic

        // Maintainability Index
        let H = Double(totalCyclomatic + 1)
        let M = Double(totalFunctions + 1)
        let LOC = Double(totalLinesOfCode + 1)
        let rawMI = 171.0
            - 5.2 * log(H)
            - 0.23 * log(M)
            - 16.2 * log(LOC)
        let normalizedMI = max(0, min(100, rawMI * 100.0 / 171.0))
        result.maintainabilityIndex = normalizedMI

        // Fan-Out Similarity
        let entityCount = Double(allEntities.count)
        if entityCount > 0 {
            result.fanOutSimilarity = Double(totalOutgoingDependencies) / entityCount
        }

        // Dependency Depth
        result.dependencyDepth = computeMaxDependencyDepth(adjacencyList: adjacencyList)

        // Coupling
        let totalIncoming = incomingCount.values.reduce(0, +)
        result.coupling = totalIncoming

        return result
    }

    /// DFS для расчёта максимальной глубины зависимостей
    func computeMaxDependencyDepth(adjacencyList: [String: Set<String>]) -> Int {
        var cache: [String: Int] = [:]

        func dfs(_ node: String, visited: inout Set<String>) -> Int {
            if let depth = cache[node] {
                return depth
            }
            guard let neighbors = adjacencyList[node], !neighbors.isEmpty else {
                cache[node] = 0
                return 0
            }
            visited.insert(node)
            var maxDepth = 0
            for neighbor in neighbors {
                if visited.contains(neighbor) { continue }
                let depth = 1 + dfs(neighbor, visited: &visited)
                maxDepth = max(maxDepth, depth)
            }
            visited.remove(node)
            cache[node] = maxDepth
            return maxDepth
        }

        var overallMax = 0
        for key in adjacencyList.keys {
            var visited: Set<String> = []
            let depth = dfs(key, visited: &visited)
            overallMax = max(overallMax, depth)
        }
        return overallMax
    }
}
