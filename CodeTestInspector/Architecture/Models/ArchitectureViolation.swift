//
//  ArchitectureViolation.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 28.05.2025.
//

import Foundation

struct ArchitectureViolation {
    let fromClass: String
    let fromComponent: String
    let toClass: String
    let toComponent: String
    let filePath: String
}
