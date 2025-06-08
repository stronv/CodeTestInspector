//
//  CohesionViewData.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation

struct CohesionViewData {
    let allSCCs: [[String]]
    let largeSCCs: [[String]]
    let suggestions: [CohesionSuggestion]
    let refactoringPlans: [String: RefactoringPlan]
}
