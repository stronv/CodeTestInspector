//
//  CohesionSuggestion.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation

struct CohesionSuggestion {
    let component: [String]
    let message: String
    let involvedDependencies: [(source: String, destination: String)]?
}
