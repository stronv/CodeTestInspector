//
//  ClassInfo.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 20.04.2025.
//

import Foundation

struct ClassInfo {
    let name: String
    let type: String
    let dependencies: [String]
    let filePath: String
    let codeLines: [String]
}
