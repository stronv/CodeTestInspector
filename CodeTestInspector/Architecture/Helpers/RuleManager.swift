//
//  RuleManager.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 26.05.2025.
//

import Foundation

final class RuleManager: ObservableObject {
    @Published var rawRules: String = ""
    @Published private(set) var parsedRules: Set<DependencyRule> = []
    
    func parseRules() {
        let lines = rawRules.components(separatedBy: .newlines)
        var result: Set<DependencyRule> = []
        
        for line in lines.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }) where !line.isEmpty {
            let parts = line.components(separatedBy: "-").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
            if parts.count == 2 {
                result.insert(DependencyRule(from: parts[0], to: parts[1]))
            }
        }
        
        parsedRules = result
    }
    
    func isAllowed(from: String, to: String) -> Bool {
        parsedRules.contains(DependencyRule(from: from.lowercased(), to: to.lowercased()))
    }
}
