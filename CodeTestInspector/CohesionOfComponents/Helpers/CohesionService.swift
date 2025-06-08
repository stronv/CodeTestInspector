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
    func computeCohesion(
        for files: [URL],
        allNames: Set<String>
    ) -> (result: CohesionResult, classEntities: [ClassDependencyEntity], methodEntities: [MethodDependencyEntity])
}

/// Сервис, который собирает полный граф и применяет Tarjan
final class CohesionService: CohesionServiceProtocol {
    private let classDependencyCollectorFactory: (Set<String>, String) -> ClassDependencyCollector
    private let methodDependencyCollectorFactory: (String, String) -> MethodDependencyCollector
    private let refactoringSuggestionService: RefactoringSuggestionService

    init(
        classCollectorFactory: @escaping (Set<String>, String) -> ClassDependencyCollector = ClassDependencyCollector.init,
        methodCollectorFactory: @escaping (String, String) -> MethodDependencyCollector = MethodDependencyCollector.init,
        refactoringSuggestionService: RefactoringSuggestionService = RefactoringSuggestionService()
    ) {
        self.classDependencyCollectorFactory = classCollectorFactory
        self.methodDependencyCollectorFactory = methodCollectorFactory
        self.refactoringSuggestionService = refactoringSuggestionService
    }

    /// Основной метод: получаем полный граф зависимостей (классы + методы), затем Tarjan.
    /// Возвращает кортеж из:
    ///   — result:  CohesionResult,
    ///   — classEntities: список всех найденных ClassDependencyEntity,
    ///   — methodEntities: список всех найденных MethodDependencyEntity.
    func computeCohesion(
        for files: [URL],
        allNames: Set<String>
    ) -> (result: CohesionResult, classEntities: [ClassDependencyEntity], methodEntities: [MethodDependencyEntity]) {
        // 1) Подготовим массивы, куда будем накапливать все сущности
        var collectedClassEntities: [ClassDependencyEntity] = []
        var collectedMethodEntities: [MethodDependencyEntity] = []

        // 2) Строим граф зависимостей классов (и одновременно заполняем collectedClassEntities)
        var classAdj: [String: Set<String>] = [:]
        for fileURL in files {
            guard let source = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            let tree = Parser.parse(source: source)

            // Запускаем ClassDependencyCollector
            let classCollector = classDependencyCollectorFactory(allNames, fileURL.path)
            classCollector.walk(tree)

            // Собираем все ClassDependencyEntity из данного файла
            collectedClassEntities.append(contentsOf: classCollector.entities)

            // Заполняем граф на уровне классов
            for e in classCollector.entities {
                let nodeKey = "C:\(e.name)"
                let deps: Set<String> = e.dependencies
                    .map { "C:\($0)" }
                    .reduce(into: Set<String>()) { $0.insert($1) }
                classAdj[nodeKey] = deps
            }
        }
        for name in allNames {
            let key = "C:\(name)"
            if classAdj[key] == nil {
                classAdj[key] = []
            }
        }

        // 3) Строим граф зависимостей методов (и одновременно заполняем collectedMethodEntities)
        var methodAdj: [String: Set<String>] = [:]
        for fileURL in files {
            guard let source = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            let tree = Parser.parse(source: source)

            let classCollector = classDependencyCollectorFactory(allNames, fileURL.path)
            classCollector.walk(tree)

            // Для каждого найденного класса запускаем MethodDependencyCollector
            for classEntity in classCollector.entities {
                let methodCollector = methodDependencyCollectorFactory(classEntity.name, fileURL.path)
                methodCollector.walk(tree)

                // Собираем все MethodDependencyEntity из данного файла
                collectedMethodEntities.append(contentsOf: methodCollector.entities)

                // Заполняем граф на уровне методов
                for m in methodCollector.entities {
                    let methodKey = "M:\(m.methodName)"
                    let depsSet: Set<String> = m.dependencies.map { depName in
                        // Ожидаем, что m.dependencies уже содержат "ClassName.methodName()"
                        return "M:\(depName)"
                    }.reduce(into: Set<String>()) { $0.insert($1) }
                    methodAdj[methodKey] = depsSet
                }
            }
        }

        // 4) Объединяем и нормализуем графы классов и методов
        let fullAdj = mergeAndNormalizeGraphs(classAdj: classAdj, methodAdj: methodAdj)

        // 5) Запускаем Tarjan и фильтруем SCC
        let (allSCCs, largeSCCs) = findAndFilterSCCs(from: fullAdj)

        // 6) Собираем детальную информацию (internalDependencies) для каждой крупной SCC
        let largeSCCDetails = collectDetailedSCCs(largeSCCs: largeSCCs, fullAdj: fullAdj)

        // 7) Генерируем рекомендации (CohesionSuggestion) на основе детальной информации
        let suggestions = refactoringSuggestionService.suggestRefactorings(for: largeSCCDetails)

        // 8) Формируем итоговый CohesionResult
        let result = CohesionResult(
            sccs: allSCCs,
            largeSCCs: largeSCCs,
            largeSCCDetails: largeSCCDetails,
            suggestions: suggestions
        )

        // 9) Возвращаем результат вместе с накопленными сущностями
        return (result, collectedClassEntities, collectedMethodEntities)
    }
}

// MARK: - Private Methods

private extension CohesionService {
    /// Объединяет графы классов и методов и добавляет любые недостающие узлы (без зависимостей).
    func mergeAndNormalizeGraphs(
        classAdj: [String: Set<String>],
        methodAdj: [String: Set<String>]
    ) -> [String: Set<String>] {
        var fullAdj: [String: Set<String>] = [:]

        // Сначала копируем весь classAdj
        for (k, v) in classAdj {
            fullAdj[k] = v
        }
        // Затем добавляем/перезаписываем метод-level
        for (k, v) in methodAdj {
            fullAdj[k] = v
        }

        // Убедимся, что все зависимости тоже представлены в ключах
        let allKeys = Set(fullAdj.keys)
        for deps in fullAdj.values {
            for dep in deps {
                if !allKeys.contains(dep) {
                    fullAdj[dep] = []
                }
            }
        }

        return fullAdj
    }

    /// Запускает алгоритм Тарьяна и фильтрует сильносвязанные компоненты по размеру (>1).
    func findAndFilterSCCs(
        from fullAdj: [String: Set<String>]
    ) -> (allSCCs: [[String]], largeSCCs: [[String]]) {
        let sccResult = tarjanSCC(adjList: fullAdj)
        let largeSCCs = sccResult.components.filter { $0.count > 1 }
        return (sccResult.components, largeSCCs)
    }

    /// Собирает детальную информацию (внутренние ребра) для каждой крупной SCC.
    func collectDetailedSCCs(
        largeSCCs: [[String]],
        fullAdj: [String: Set<String>]
    ) -> [DetailedSCC] {
        var largeSCCDetails: [DetailedSCC] = []

        for sccNodes in largeSCCs {
            var internalDependencies: [(source: String, destination: String)] = []
            let sccNodeSet = Set(sccNodes)

            for sourceNode in sccNodes {
                if let dependencies = fullAdj[sourceNode] {
                    for destinationNode in dependencies {
                        // Если ребро ведёт внутри той же SCC, запоминаем его
                        if sccNodeSet.contains(destinationNode) {
                            internalDependencies.append((source: sourceNode, destination: destinationNode))
                        }
                    }
                }
            }

            largeSCCDetails.append(
                DetailedSCC(nodes: sccNodes, internalDependencies: internalDependencies)
            )
        }

        return largeSCCDetails
    }
}
