//
//  DependencyGraph.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 20.04.2025.
//

import Foundation
import SwiftSyntax

public protocol IDependencyGraph: AnyObject {
    func addDependency(from node: String, to dependency: String)
    func getStronglyConnectedComponents() -> [[String]]
    func findCycles() -> [[String]]
    func calculateLongestPath() -> Int
    func suggestImprovements() -> [String]
    func calculateMetrics() -> [String: Any]
}

public final class DependencyGraph {
    var adjacencyList: [String: Set<String>] = [:]
    
    public func addDependency(from node: String, to dependency: String) {
        adjacencyList[node, default: []].insert(dependency)
    }
    
    public func getStronglyConnectedComponents() -> [[String]] {
        let tarjan = TarjanSCC(adjacencyList: adjacencyList)
        return tarjan.findSCCs()
    }
    
    public func findCycles() -> [[String]] {
        let tarjan = TarjanSCC(adjacencyList: adjacencyList)
        let allSCCs = tarjan.findSCCs()
        
        // Filter out single-node SCCs that are not relevant
        return allSCCs.filter { $0.count > 1 && !$0.contains("CurrentModule") }
    }
}

extension DependencyGraph {
    func calculateLongestPath() -> Int {
        var visited = Set<String>()
        var longestPath = 0
        
        func dfs(node: String, depth: Int) {
            visited.insert(node)
            longestPath = max(longestPath, depth)
            for neighbor in adjacencyList[node] ?? [] {
                if !visited.contains(neighbor) {
                    dfs(node: neighbor, depth: depth + 1)
                }
            }
            visited.remove(node)
        }
        
        for node in adjacencyList.keys {
            dfs(node: node, depth: 1)
        }
        return longestPath
    }
}

extension DependencyGraph {
    func suggestImprovements() -> [String] {
        var suggestions: [String] = []
        
        // Suggest reducing strong cyclic dependencies
        let cycles = findCycles()
        for cycle in cycles {
            suggestions.append("Consider breaking the cycle: \(cycle.joined(separator: " -> ")) by introducing protocols or dependency injection.")
        }
        
        // Suggest abstracting common dependencies
        let inDegree = adjacencyList.reduce(into: [String: Int]()) { result, pair in
            pair.value.forEach { result[$0, default: 0] += 1 }
        }
        let highInDegreeNodes = inDegree.filter { $0.value > 1 }
        for (node, count) in highInDegreeNodes {
            suggestions.append("Class '\(node)' is highly depended upon (\(count) times). Consider introducing a protocol to decouple it.")
        }
        return suggestions
    }
    
    func calculateMetrics() -> [String: Any] {
        let sccs = getStronglyConnectedComponents()
        let totalEdges = adjacencyList.values.reduce(0) { $0 + $1.count }
        let totalNodes = adjacencyList.keys.count
        
        // SCC Count
        let sccCount = sccs.count
        
        // Connectivity Index
        let maxEdges = totalNodes > 1 ? totalNodes - 1 : 1
        let connectivityIndex = totalEdges > 0 ? Double(totalEdges) / Double(maxEdges) : 0.0
        
        // Depth of Dependencies
        let longestPath = calculateLongestPath()
        
        // Degree Metrics
        let inDegree = adjacencyList.reduce(into: [String: Int]()) { result, pair in
            pair.value.forEach { result[$0, default: 0] += 1 }
        }
        let outDegree = adjacencyList.mapValues { $0.count }
        
        return [
            "sccCount": sccCount,
            "connectivityIndex": connectivityIndex,
            "longestPath": longestPath,
            "inDegree": inDegree,
            "outDegree": outDegree
        ]
    }
}
