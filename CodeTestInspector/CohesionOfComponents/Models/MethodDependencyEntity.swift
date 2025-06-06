//
//  MethodDependencyEntity.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation

struct MethodDependencyEntity {
    let parentEntityName: String
    let methodName: String
    var dependencies: Set<String>
    let filePath: String
}
