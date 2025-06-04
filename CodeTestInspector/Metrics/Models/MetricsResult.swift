//
//  MetricsResult.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 01.06.2025.
//

import Foundation

struct MetricsResult {
    // 1. Cyclomatic Complexity (на уровне всего проекта или среднее по функциям)
    var totalCyclomatic: Int = 0
    // 2. Maintainability Index (может быть одно число для всего проекта или среднее)
    var maintainabilityIndex: Double = 0.0
    // 3. Fan-Out Similarity (отношение общего числа зависимостей / число сущностей)
    var fanOutSimilarity: Double = 0.0
    // 4. Dependency Depth (максимальная глубина в графе зависимостей)
    var dependencyDepth: Int = 0
    // 5. Coupling (количество обратных связей или кол-во incoming edges)
    var coupling: Int = 0
}
