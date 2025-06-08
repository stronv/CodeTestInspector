//  DetailedSCC.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation

/// Детальная информация о сильносвязанной компоненте, включая внутренние зависимости.
struct DetailedSCC {
    let nodes: [String]
    let internalDependencies: [(source: String, destination: String)]
}
