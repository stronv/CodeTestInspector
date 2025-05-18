//
//  Violation.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 20.04.2025.
//

import Foundation

struct Violation: Identifiable {
    let id = UUID()
    let className: String
    let issue: String
    let recommendation: String
    let filePath: String
    let codeSnippet: String
    let lineNumber: Int
}
