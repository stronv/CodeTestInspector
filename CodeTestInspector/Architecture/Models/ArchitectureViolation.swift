//
//  ArchitectureViolation.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 28.05.2025.
//

import Foundation

struct ArchitectureViolation: Identifiable {
    let id = UUID()
    let fromClass: String
    let fromComponent: String
    let toClass: String
    let toComponent: String
    let filePath: String
    let lineNumber: Int?
    let snippetLines: [(Int, String)]
}
