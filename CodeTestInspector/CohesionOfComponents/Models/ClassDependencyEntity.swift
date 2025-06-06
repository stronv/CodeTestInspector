//
//  ClassDependencyEntity.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation

struct ClassDependencyEntity {
    let name: String
    var dependencies: Set<String>
    let filePath: String
}
