//
//  AnalyzerEngine.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 25.05.2025.
//

import Foundation
import SwiftParser
import SwiftSyntax

protocol AnalyzerEngineProtocol {
    func collectEntities(at path: URL) -> [ParsedEntity]
}

final class AnalyzerEngine: AnalyzerEngineProtocol {
    private let scanner = ProjectScanner()
    
    func collectEntities(at path: URL) -> [ParsedEntity] {
        var entities: [ParsedEntity] = []
        let files = scanner.scan(at: path)

        for fileURL in files {
            do {
                let source = try String(contentsOf: fileURL, encoding: .utf8)
                let syntax = Parser.parse(source: source)
                let walker = EntitySyntaxWalker(filePath: fileURL.path)
                walker.walk(syntax)
                entities.append(contentsOf: walker.entities)
            } catch {
                print("Ошибка при обработке \(fileURL.path): \(error)")
            }
        }

        return entities
    }
}

