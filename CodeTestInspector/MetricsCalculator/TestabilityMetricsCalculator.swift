//
//  TestabilityMetricsCalculator.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 29.04.2025.
//

import Foundation

// MARK: - Mocks

final class TestabilityMetricsCalculator {
    let graph: DependencyGraph

    init(graph: DependencyGraph) {
        self.graph = graph
    }

    func calculateMetrics() -> [String: Any] {
        let totalClasses = graph.adjacencyList.keys.count
        let totalDependencies = graph.adjacencyList.values.reduce(0) { $0 + $1.count }

        let coupling = totalClasses > 0 ? Double(totalDependencies) / Double(totalClasses) : 0
        let cohesion = calculateCohesion()
        let cyclomaticComplexity = estimateCyclomaticComplexity()
        let maintainabilityIndex = estimateMaintainabilityIndex(cohesion: cohesion, coupling: coupling, complexity: cyclomaticComplexity)
        let dependencyDepth = graph.calculateLongestPath()
        let fanOutSimilarity = calculateFanOutSimilarity()

        return [
            "Total Classes": totalClasses,
            "Total Dependencies": totalDependencies,
            "Coupling": String(format: "%.2f", coupling),
            "Cohesion": String(format: "%.2f", cohesion),
            "Cyclomatic Complexity": cyclomaticComplexity,
            "Dependency Depth": dependencyDepth,
            "Fan-Out Similarity": String(format: "%.2f", fanOutSimilarity),
            "Maintainability Index": String(format: "%.2f", maintainabilityIndex)
        ]
    }

    private func calculateCohesion() -> Double {
        let total = graph.adjacencyList.reduce(0) { $0 + ($1.value.contains($1.key) ? 1 : 0) }
        return graph.adjacencyList.isEmpty ? 0 : Double(total) / Double(graph.adjacencyList.count)
    }

    private func estimateCyclomaticComplexity() -> Int {
        return graph.adjacencyList.values.reduce(0) { $0 + $1.count } + 1
    }

    private func estimateMaintainabilityIndex(cohesion: Double, coupling: Double, complexity: Int) -> Double {
        return 100.0 - (Double(complexity) * 1.5) - (coupling * 10) + (cohesion * 20)
    }
    
    private func calculateFanOutSimilarity() -> Double {
        let all = graph.adjacencyList.mapValues { $0 }

        var totalSimilarity: Double = 0
        var count: Int = 0

        let keys = Array(all.keys)
        for i in 0..<keys.count {
            for j in (i + 1)..<keys.count {
                let setA = all[keys[i]] ?? []
                let setB = all[keys[j]] ?? []

                if setA.isEmpty && setB.isEmpty { continue }

                let intersection = setA.intersection(setB).count
                let union = setA.union(setB).count

                let similarity = Double(intersection) / Double(union)
                totalSimilarity += similarity
                count += 1
            }
        }

        return count > 0 ? totalSimilarity / Double(count) : 0.0
    }
}

