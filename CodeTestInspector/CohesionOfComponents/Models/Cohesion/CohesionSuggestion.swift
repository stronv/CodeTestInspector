//
//  CohesionSuggestion.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation

struct CohesionSuggestion {
    let component: [String]     // один SCC, например ["C:UserA", "C:UserB", "M:UserA.doSomething()", ...]
    let message: String         // рекомендация, например: "Классы A и B сильно связаны. Рассмотрите возможность вынести интерфейс X"
}
