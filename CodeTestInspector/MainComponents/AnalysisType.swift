//
//  AnalysisType.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 01.06.2025.
//

import Foundation

enum AnalysisType: String, CaseIterable, Identifiable {
    case architecture = "Архитектура"
    case metrics = "Метрики"
    
    var id: AnalysisType { self }
}
