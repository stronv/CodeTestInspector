//
//  TestabilityAnalyzer.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 29.04.2025.
//

import Foundation

// MARK: - Mocks

struct TestabilityAnalyzer {
    static func analyze(projectPath: String) throws -> DependencyGraph {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: projectPath) else {
            throw NSError(domain: "TestabilityAnalyzer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Не удалось прочитать директорию"])
        }

        var sources: [String] = []

        for case let file as String in enumerator {
            if file.hasSuffix(".swift") {
                let fullPath = (projectPath as NSString).appendingPathComponent(file)
                if let code = try? String(contentsOfFile: fullPath) {
                    sources.append(code)
                }
            }
        }

        return analyzeMultipleSources(sources)
    }
}

