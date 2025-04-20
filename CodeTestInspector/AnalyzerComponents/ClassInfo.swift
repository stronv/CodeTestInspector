//
//  ClassInfo.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 20.04.2025.
//

import Foundation

struct ClassInfo {
    let name: String
    let type: MVVMComponent
    let dependencies: [String] // имена других классов
    let filePath: String
    let codeLines: [String]
}
