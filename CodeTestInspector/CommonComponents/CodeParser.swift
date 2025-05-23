//
//  CodeParser.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 20.04.2025.
//

import SwiftSyntax
import SwiftParser
import Foundation

public class CodeParser {
    // Private properties
    private let excludedTypes: Set<String> = [
        "super", "UIView", "UIStackView", "NSLayoutConstraint",
        "UILabel", "UIButton", "UITableView", "UICollectionView",
        "CALayer", "UIColor", "UIFont", "UIImageView"
        // Можно дополнить по проекту
    ]
    
    public init() {}
}

// MARK: - Public methods

extension CodeParser {
    public func buildDependencyGraph(from source: String) throws -> DependencyGraph {
        let visitor = try extractVisitor(from: source)
        let graph = DependencyGraph()

        for (origin, target) in visitor.dependencies {
            let originClass = extractClassName(from: origin)
            let targetClass = extractClassName(from: target)

            guard !excludedTypes.contains(targetClass) else { continue }

            graph.addDependency(from: originClass, to: targetClass)
        }

        let allNodes = visitor.dependencies.flatMap { [$0.origin, $0.target] }
        for node in allNodes {
            let name = extractClassName(from: node)
            guard !excludedTypes.contains(name) else { continue }
            _ = graph.adjacencyList[name, default: []]
        }

        return graph
    }

    func extractVisitor(from source: String) throws -> CodeVisitor {
        let sourceFile = Parser.parse(source: source)
        let visitor = CodeVisitor(viewMode: .sourceAccurate)
        visitor.walk(sourceFile)
        return visitor
    }
}

private extension CodeParser {
    func extractClassName(from identifier: String) -> String {
        return identifier
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "!", with: "")
            .replacingOccurrences(of: "()", with: "")
            .components(separatedBy: ".").first ?? identifier
    }
}

import Dispatch

func analyzeMultipleSources(_ sources: [String]) -> DependencyGraph {
    let graph = DependencyGraph()
    let queue = DispatchQueue(label: "dependency-merge-queue")
    let group = DispatchGroup()

    for source in sources {
        group.enter()
        DispatchQueue.global().async {
            defer { group.leave() }
            if let parsed = try? CodeParser().buildDependencyGraph(from: source) {
                queue.sync {
                    graph.merge(with: parsed)
                }
            }
        }
    }

    group.wait()
    return graph
}

extension DependencyGraph {
    func merge(with other: DependencyGraph) {
        for (key, targets) in other.adjacencyList {
            adjacencyList[key, default: []].formUnion(targets)
        }
    }
}

// TODO: Move to another place

struct DependencyGraphJSON: Codable {
    struct Node: Codable {
        let id: String
        let type: String
    }
    
    struct Edge: Codable {
        let source: String
        let target: String
    }
    
    var nodes: [Node]
    var edges: [Edge]
}

func generateJSON(for graph: DependencyGraph) -> String {
    var nodes: [DependencyGraphJSON.Node] = []
    var edges: [DependencyGraphJSON.Edge] = []
    
    for (node, targets) in graph.adjacencyList {
        nodes.append(DependencyGraphJSON.Node(id: node, type: "class"))
        for target in targets {
            edges.append(DependencyGraphJSON.Edge(source: node, target: target))
        }
    }
    
    let jsonGraph = DependencyGraphJSON(nodes: nodes, edges: edges)
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted // Для красивого вывода
    if let jsonData = try? encoder.encode(jsonGraph), let jsonString = String(data: jsonData, encoding: .utf8) {
        return jsonString
    }
    
    return "{}"
}
