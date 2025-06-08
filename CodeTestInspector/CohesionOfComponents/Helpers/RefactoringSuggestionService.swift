//  RefactoringSuggestionService.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation

/// Сервис для анализа детальной информации о SCC и генерации рекомендаций по рефакторингу.
final class RefactoringSuggestionService {
    /// Анализирует детальные SCC и предлагает рекомендации по рефакторингу.
    /// - Parameter detailedSCCs: Массив детальной информации о сильносвязанных компонентах.
    /// - Returns: Массив рекомендаций по рефакторингу.
    func suggestRefactorings(for detailedSCCs: [DetailedSCC]) -> [CohesionSuggestion] {
        var suggestions: [CohesionSuggestion] = []
        
        for scc in detailedSCCs {
            // Фокусируемся на SCC с двумя узлами, оба из которых - классы
            if scc.nodes.count == 2 && scc.nodes.allSatisfy({ $0.hasPrefix("C:") }) {
                let node1 = scc.nodes[0] // Например, "C:ClassA"
                let node2 = scc.nodes[1] // Например, "C:ClassB"
                let className1 = node1.dropFirst(2) // "ClassA"
                let className2 = node2.dropFirst(2) // "ClassB"
                
                // Находим зависимости от Class1 (или его методов) к Class2 (или его методам)
                let deps1to2 = scc.internalDependencies.filter { dep in
                    let sourceIsNode1 = dep.source == node1 || dep.source.hasPrefix("M:\(className1).")
                    let destIsNode2 = dep.destination == node2 || dep.destination.hasPrefix("M:\(className2).")
                    return sourceIsNode1 && destIsNode2
                }
                
                // Находим зависимости от Class2 (или его методов) к Class1 (или его методам)
                let deps2to1 = scc.internalDependencies.filter { dep in
                    let sourceIsNode2 = dep.source == node2 || dep.source.hasPrefix("M:\(className2).")
                    let destIsNode1 = dep.destination == node1 || dep.destination.hasPrefix("M:\(className1).")
                    return sourceIsNode2 && destIsNode1
                }
                
                // Если есть зависимости в обе стороны, это взаимная зависимость
                if !deps1to2.isEmpty && !deps2to1.isEmpty {
                    let message = "Классы '\(className1)' и '\(className2)' имеют взаимную зависимость. Рассмотрите возможность извлечения протокола для одного из классов, чтобы разорвать цикл."
                    
                    // Собираем все зависимости между этими двумя классами внутри SCC
                    let allInvolvedDependencies = deps1to2 + deps2to1
                    
                    suggestions.append(CohesionSuggestion(
                        component: scc.nodes,
                        message: message,
                        involvedDependencies: allInvolvedDependencies // Сохраняем найденные зависимости
                    ))
                }
            }
        }
        return suggestions
    }
}
