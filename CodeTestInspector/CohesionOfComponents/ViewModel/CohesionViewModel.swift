//
//  CohesionViewModel.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation
import SwiftSyntax
import SwiftParser

final class CohesionViewModel: ObservableObject {
    @Published var cohesionData: CohesionViewData? = nil
    @Published var codeDiffs: [(filePath: String, lines: [DiffLine])] = []

    private let service: CohesionServiceProtocol
    private let nameService: NameCollectorService
    private let projectScanner: ProjectScannerProtocol
    private let refactoringCodeGeneratorService: RefactoringCodeGeneratorService

    private var modifiedSourceCode: String?
    private var modifiedDependentCode: String?

    private var projectURL: URL?
    private var projectBookmark: Data?

    init(
        service: CohesionServiceProtocol = CohesionService(),
        nameService: NameCollectorService = NameCollectorService(),
        projectScanner: ProjectScannerProtocol = ProjectScanner(),
        refactoringCodeGeneratorService: RefactoringCodeGeneratorService = RefactoringCodeGeneratorService()
    ) {
        self.service = service
        self.nameService = nameService
        self.projectScanner = projectScanner
        self.refactoringCodeGeneratorService = refactoringCodeGeneratorService
    }

    func computeCohesion(for path: URL) {
        self.projectURL = path
        if let bookmark = try? path.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) {
            self.projectBookmark = bookmark
        }

        // 1) Получаем все Swift-файлы в выбранной папке
        let swiftFiles = projectScanner.scan(at: path)

        // 2) Собираем все уникальные имена классов/структур/протоколов
        var allNames: Set<String> = []
        for fileURL in swiftFiles {
            guard let source = try? String(contentsOfFile: fileURL.path, encoding: .utf8) else { continue }
            let tree = Parser.parse(source: source)
            let nameCollector = nameService.makeNameCollector()
            nameCollector.walk(tree)
            allNames.formUnion(nameCollector.names)
        }

        // 3) Вызываем сервис для расчёта SCC и получаем список всех сущностей
        let (cohesionResult, classEntities, methodEntities) = service.computeCohesion(
            for: swiftFiles,
            allNames: allNames
        )

        // 4) На основе рекомендаций строим планы рефакторинга
        var refactoringPlans: [String: RefactoringPlan] = [:]
        for suggestion in cohesionResult.suggestions {
            let key = suggestion.component
                .map { String($0.dropFirst(2)) }      // убираем префиксы C: и M:
                .sorted()
                .joined(separator: ",")
            if let plan = refactoringCodeGeneratorService.planRefactoring(
                for: suggestion,
                classEntities: classEntities,
                methodEntities: methodEntities
            ) {
                refactoringPlans[key] = plan
            }
        }

        // 5) Обновляем Published-свойство, чтобы UI увидел новые данные
        DispatchQueue.main.async {
            self.cohesionData = CohesionViewData(
                allSCCs: cohesionResult.sccs,
                largeSCCs: cohesionResult.largeSCCs,
                suggestions: cohesionResult.suggestions,
                refactoringPlans: refactoringPlans
            )
        }
    }

    // MARK: - Refactoring Actions


    func applyRefactoringPlan(_ plan: RefactoringPlan) {
        guard plan.type == .extractProtocol,
              let details = plan.protocolDetails else {
            self.codeDiffs = []
            return
        }

        // 1) Читаем оригиналы
        guard let origSrc = try? String(contentsOfFile: details.sourceFilePath, encoding: .utf8),
              let origDep = try? String(contentsOfFile: details.dependentFilePath, encoding: .utf8)
        else {
            self.codeDiffs = []
            return
        }

        // 2) Генерим новые тексты
        let newSrc = refactoringCodeGeneratorService.modifySourceClass(
            originalCode: origSrc,
            plan: plan
        ) ?? origSrc

        let newDep = refactoringCodeGeneratorService.modifyDependentClass(
            originalDependentCode: origDep,
            plan: plan
        ) ?? origDep

        // 3) Сохраняем для записи
        self.modifiedSourceCode = newSrc
        self.modifiedDependentCode = newDep

        // 4) Считаем по-файловые diffs (только added/removed)
        let srcDiff = computeMinimalDiff(new: newSrc, old: origSrc)
        let depDiff = computeMinimalDiff(new: newDep, old: origDep)

        // 5) Публикуем array из двух превью
        DispatchQueue.main.async {
            self.codeDiffs = [
                (filePath: details.sourceFilePath, lines: srcDiff),
                (filePath: details.dependentFilePath, lines: depDiff)
            ]
        }
    }

    func saveRefactoringChanges() {
        guard
            let details = cohesionData?
                .refactoringPlans
                .values
                .first(where: { $0.type == .extractProtocol })?
                .protocolDetails,
            let newSrc = modifiedSourceCode,
            let newDep = modifiedDependentCode,
            let bookmark = projectBookmark
        else {
            print("❌ Нечего сохранять или нет bookmark")
            return
        }

        // Разворачиваем URL из bookmark
        var isStale = false
        guard
            let projURL = try? URL(
                resolvingBookmarkData: bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ),
            projURL.startAccessingSecurityScopedResource()
        else {
            print("❌ Не удалось получить access к песочнице")
            return
        }
        defer { projURL.stopAccessingSecurityScopedResource() }

        // Строим абсолютные URL
        let relSrc = details.sourceFilePath
            .replacingOccurrences(of: projURL.path + "/", with: "")
        let relDep = details.dependentFilePath
            .replacingOccurrences(of: projURL.path + "/", with: "")
        let srcURL = projURL.appendingPathComponent(relSrc)
        let depURL = projURL.appendingPathComponent(relDep)

        do {
            try newSrc.write(to: srcURL, atomically: true, encoding: .utf8)
            try newDep.write(to: depURL, atomically: true, encoding: .utf8)
            print("✅ Файлы успешно сохранены:\n  \(srcURL.path)\n  \(depURL.path)")
        } catch {
            print("❌ Ошибка при записи файлов: \(error)")
        }
    }
    
    private func computeMinimalDiff(new: String, old: String) -> [DiffLine] {
        let newLines = new.components(separatedBy: "\n")
        let oldLines = old.components(separatedBy: "\n")
        let diff = newLines.difference(from: oldLines)

        var result: [DiffLine] = []
        for change in diff {
            switch change {
            case let .remove(_, element, _):
                result.append(.init(text: element, type: .removed))
            case let .insert(_, element, _):
                result.append(.init(text: element, type: .added))
            }
        }
        return result
    }
}

// MARK: - Модель для отображения diff

struct DiffLine: Identifiable {
    let id = UUID()
    let text: String
    let type: DiffLineType
}

enum DiffLineType {
    case added, removed
}

extension Array where Element == String {
    func minimalDiffLines(comparedTo other: [String]) -> [DiffLine] {
        let diff = self.difference(from: other)
        var result: [DiffLine] = []

        for change in diff {
            switch change {
            case let .remove(_, element, _):
                result.append(.init(text: element, type: .removed))
            case let .insert(_, element, _):
                result.append(.init(text: element, type: .added))
            }
        }

        return result
    }
}
