//
//  ParsedEntity.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 25.05.2025.
//

import Foundation

enum EntityType {
    case `class`, `struct`, `protocol`
}

struct ParsedEntity {
    let name: String
    let type: EntityType
    let filePath: String
}
