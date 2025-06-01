//
//  TarjanSCC.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 20.04.2025.
//

import Foundation
import SwiftSyntax

protocol ITarjanSCC: AnyObject {
    func findSCCs() -> [[String]]
}

public class TarjanSCC: ITarjanSCC {
    private var graph: [String: Set<String>]
    private var index = 0
    private var stack: [String] = []
    private var indices: [String: Int] = [:]
    private var lowLink: [String: Int] = [:]
    private var onStack: Set<String> = []
    private var sccs: [[String]] = []
    
    init(adjacencyList: [String: Set<String>]) {
        self.graph = adjacencyList
    }
    
    // MARK: - ITarjanSCC
    
    func findSCCs() -> [[String]] {
        for node in graph.keys {
            if indices[node] == nil {
                strongConnect(node)
            }
        }
        return sccs
    }
}

// MARK: - TarjanSCC

private extension TarjanSCC {
    func strongConnect(_ node: String) {
        indices[node] = index
        lowLink[node] = index
        index += 1
        stack.append(node)
        onStack.insert(node)
        
        for neighbor in graph[node] ?? [] {
            print("  Checking neighbor: \(neighbor)")
            if indices[neighbor] == nil {
                strongConnect(neighbor)
                lowLink[node] = min(lowLink[node]!, lowLink[neighbor]!)
            } else if onStack.contains(neighbor) {
                lowLink[node] = min(lowLink[node]!, indices[neighbor]!)
            }
        }
        
        if lowLink[node] == indices[node] {
            var scc: [String] = []
            var w: String
            repeat {
                w = stack.removeLast()
                onStack.remove(w)
                scc.append(w)
            } while w != node
//            print("Found SCC: \(scc)")
            sccs.append(scc)
        }
    }
}

