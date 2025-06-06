//
//  CohesionViewModel.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation
import SwiftParser

final class CohesionViewModel: ObservableObject {
    @Published var cohesionData: CohesionViewData? = nil

    private let service: CohesionServiceProtocol
    private let nameService: NameCollectorService
    private let metricsService: ProjectScannerProtocol

    init(
        service: CohesionServiceProtocol = CohesionService(),
        nameService: NameCollectorService = NameCollectorService(),
        projectScanner: ProjectScannerProtocol = ProjectScanner()
    ) {
        self.service = service
        self.nameService = nameService
        self.metricsService = projectScanner
    }

    func computeCohesion(for path: URL) {
        let swiftFiles = metricsService.scan(at: path)

        var allNames: Set<String> = []
        for fileURL in swiftFiles {
            guard let source = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            let tree = Parser.parse(source: source)
            let nameCollector = nameService.makeNameCollector()
            nameCollector.walk(tree)
            allNames.formUnion(nameCollector.names)
        }

        let cohesionResult = service.computeCohesion(for: swiftFiles, allNames: allNames)

        var suggestions: [CohesionSuggestion] = []
        for component in cohesionResult.largeSCCs {
            let classesInComp = component.filter { $0.hasPrefix("C:") }
            if classesInComp.count > 1 {
                let classList = classesInComp.map { $0.replacingOccurrences(of: "C:", with: "") }.joined(separator: ", ")
                let msg = "Классы [\(classList)] образуют циклическую зависимость. Рассмотрите возможность выделения общего интерфейса или внедрения зависимостей через протоколы."
                suggestions.append(.init(component: component, message: msg))
            }
        }

        DispatchQueue.main.async {
            self.cohesionData = CohesionViewData(allSCCs: cohesionResult.sccs, largeSCCs: cohesionResult.largeSCCs, suggestions: suggestions)
        }
    }
}
