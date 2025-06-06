//
//  CohesionViewData.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation

struct CohesionViewData {
    let allSCCs: [[String]]     // все SCC (можем отображать в виде списка или дерева)
    let largeSCCs: [[String]]
    let suggestions: [CohesionSuggestion]
}
