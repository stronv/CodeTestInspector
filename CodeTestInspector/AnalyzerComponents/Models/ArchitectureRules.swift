//
//  ArchitectureRules.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 20.04.2025.
//

import Foundation

struct ArchitectureRules: Codable {
    let name: String
    let rules: [ComponentRule]
}

