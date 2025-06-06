//
//  TarjanSCC.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation

/// Хранит результат «сильносвязанного компонента»
struct SCCResult {
    /// каждая компонента — это массив узлов (String)
    let components: [[String]]
}

/// Реализация алгоритма Тарьяна для поиска всех сильносвязанных компонент
func tarjanSCC(adjList: [String: Set<String>]) -> SCCResult {
    var index = 0
    var stack: [String] = []
    var indices: [String: Int] = [:]
    var lowlink: [String: Int] = [:]
    var onStack: Set<String> = []
    var sccs: [[String]] = []

    func strongconnect(_ v: String) {
        indices[v] = index
        lowlink[v] = index
        index += 1
        stack.append(v)
        onStack.insert(v)

        for w in adjList[v] ?? [] {
            if indices[w] == nil {
                // w ещё не посещён
                strongconnect(w)
                lowlink[v] = min(lowlink[v]!, lowlink[w]!)
            } else if onStack.contains(w) {
                lowlink[v] = min(lowlink[v]!, indices[w]!)
            }
        }

        // Если v — корень SCC
        if lowlink[v] == indices[v] {
            var component: [String] = []
            while true {
                let w = stack.removeLast()
                onStack.remove(w)
                component.append(w)
                if w == v { break }
            }
            sccs.append(component)
        }
    }

    // Запускаем на всех узлах
    for v in adjList.keys {
        if indices[v] == nil {
            strongconnect(v)
        }
    }

    return SCCResult(components: sccs)
}
