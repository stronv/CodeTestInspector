//
//  CohesionResult.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation

/// Модель, которая содержит все данные для оценки «сильной связности»
struct CohesionResult {
    let sccs: [[String]]
    let largeSCCs: [[String]]
    let largeSCCDetails: [DetailedSCC]
    let suggestions: [CohesionSuggestion]
}
