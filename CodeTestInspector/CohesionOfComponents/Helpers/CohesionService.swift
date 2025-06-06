//
//  CohesionService.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation
import SwiftSyntax
import SwiftParser

protocol CohesionServiceProtocol {
    func computeCohesion(for files: [URL], allNames: Set<String>) -> CohesionResult
}

/// Сервис, который собирает полный граф и применяет Tarjan
final class CohesionService: CohesionServiceProtocol {
    private let classDependencyCollectorFactory: (Set<String>, String) -> ClassDependencyCollector
    private let methodDependencyCollectorFactory: (String, String) -> MethodDependencyCollector

    init(
        classCollectorFactory: @escaping (Set<String>, String) -> ClassDependencyCollector = ClassDependencyCollector.init,
        methodCollectorFactory: @escaping (String, String) -> MethodDependencyCollector = MethodDependencyCollector.init
    ) {
        self.classDependencyCollectorFactory = classCollectorFactory
        self.methodDependencyCollectorFactory = methodCollectorFactory
    }

    /// Основной метод: получаем полный граф зависимостей (классы + методы), затем Tarjan
    func computeCohesion(for files: [URL], allNames: Set<String>) -> CohesionResult {
        var classAdj: [String: Set<String>] = [:]
        var methodAdj: [String: Set<String>] = [:]

        // 1) Сначала строим classAdj (точно так же, как раньше)
        for fileURL in files {
            guard let source = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            let tree = Parser.parse(source: source)
            let classCollector = classDependencyCollectorFactory(allNames, fileURL.path)
            classCollector.walk(tree)
            for e in classCollector.entities {
                let nodeKey = "C:\(e.name)"
                classAdj[nodeKey] = e.dependencies.map { "C:\($0)" }.reduce(into: Set()) { $0.insert($1) }
            }
        }
        // Убедимся, что у каждого «C:Name» есть entry (пусть даже пустой)
        for name in allNames {
            let key = "C:\(name)"
            if classAdj[key] == nil {
                classAdj[key] = []
            }
        }

        // 2) Для каждого класса собираем зависимости на уровне методов
        for fileURL in files {
            guard let source = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            let tree = Parser.parse(source: source)

            // Нужно запустить MethodDependencyCollector внутри каждого класса
            // Чтобы знать, какие классы есть в этом файле, можно повторить ClassDependencyCollector:
            let classCollector = classDependencyCollectorFactory(allNames, fileURL.path)
            classCollector.walk(tree)
            for classEntity in classCollector.entities {
                // Вызовем для каждого класса-entity свой MethodDependencyCollector
                let methodCollector = methodDependencyCollectorFactory(classEntity.name, fileURL.path)
                methodCollector.walk(tree)
                for m in methodCollector.entities {
                    let methodKey = "M:\(m.methodName)"
                    methodAdj[methodKey] = m.dependencies.map { depName in
                        // Теперь мапим зависимости на формат "M:<Class>.<method>()"
                        // Если в dependencies хранятся просто "OtherClass.someMethod()",
                        // можно взять за основу: "M:\(depName)" без префикса класса.
                        // Для большей точности тут нужно ещё парсить depName, чтобы понять,
                        // в каком классе расположен вызываемый метод. Упрощённо считаем, что
                        // m.dependencies содержит уже правильно сформированные ключи:
                        return depName.hasPrefix("\(classEntity.name).")
                            ? "M:\(depName)"
                            : "M:\(depName)"
                    }.reduce(into: Set()) { $0.insert($1) }
                }
            }
        }

        // 3) Объединяем оба графа в один
        var fullAdj: [String: Set<String>] = [:]
        for (k, v) in classAdj {
            fullAdj[k] = v
        }
        for (k, v) in methodAdj {
            fullAdj[k] = v
        }

        // Убедимся, что все узлы, упомянутые “встречаются” в ключах fullAdj
        let allKeys = Set(fullAdj.keys)
        for deps in fullAdj.values {
            for dep in deps {
                if !allKeys.contains(dep) {
                    fullAdj[dep] = []  // если зависимости нет как ключ, добавляем пустой entry
                }
            }
        }

        // 4) Запускаем Tarjan по fullAdj
        let sccResult = tarjanSCC(adjList: fullAdj)

        // 5) Определяем «крупные» SCC: например, все компоненты размера >= 2
        let largeSCCs = sccResult.components.filter { $0.count > 1 }

        return CohesionResult(sccs: sccResult.components, largeSCCs: largeSCCs)
    }
}
