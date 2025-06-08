//
//  RefactoringCodeGeneratorService.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation
import SwiftSyntax
import SwiftParser

final class RefactoringCodeGeneratorService {

    // MARK: — Планирование рефакторинга

    func planRefactoring(
        for suggestion: CohesionSuggestion,
        classEntities: [ClassDependencyEntity],
        methodEntities: [MethodDependencyEntity]
    ) -> RefactoringPlan? {
        // 1) Должно быть ровно две сущности-класса
        guard suggestion.component.count == 2,
              suggestion.component.allSatisfy({ $0.hasPrefix("C:") }),
              let deps = suggestion.involvedDependencies,
              !deps.isEmpty
        else { return nil }

        // 2) Приводим ["C:A","C:B"] → ["A","B"]
        let names = suggestion.component.map { String($0.dropFirst(2)) }
        let class1 = names[0], class2 = names[1]

        // 3) Собираем ребра class1→class2 и class2→class1
        let c1to2 = deps.filter {
            ($0.source.hasPrefix("C:\(class1)") || $0.source.hasPrefix("M:\(class1).")) &&
            ($0.destination.hasPrefix("C:\(class2)") || $0.destination.hasPrefix("M:\(class2)."))
        }
        let c2to1 = deps.filter {
            ($0.source.hasPrefix("C:\(class2)") || $0.source.hasPrefix("M:\(class2).")) &&
            ($0.destination.hasPrefix("C:\(class1)") || $0.destination.hasPrefix("M:\(class1)."))
        }

        // 4) Определяем, кто кандидат на протокол (тот, на который смотрят другие)
        let protocolCandidate: String
        let dependentClass: String
        let forwardDeps: [(source: String, destination: String)]

        if !c1to2.isEmpty {
            protocolCandidate = class2
            dependentClass = class1
            forwardDeps = c1to2
        } else if !c2to1.isEmpty {
            protocolCandidate = class1
            dependentClass = class2
            forwardDeps = c2to1
        } else {
            return nil
        }

        // 5) Ищем filePath для обоих классов
        guard let protoEntity = classEntities.first(where: { $0.name == protocolCandidate }),
              let depEntity   = classEntities.first(where: { $0.name == dependentClass })
        else {
            return nil
        }
        let sourceFilePath = protoEntity.filePath
        let dependentFilePath = depEntity.filePath

        // 6) Из ребер фильтруем только методные и получаем имена "bar()"
        var methodNames: [String] = []
        for d in forwardDeps {
            if d.destination.hasPrefix("M:\(protocolCandidate).") {
                let suffix = String(d.destination.dropFirst("M:\(protocolCandidate).".count))
                methodNames.append(suffix)
            }
        }

        // 7) Извлекаем полные сигнатуры из файла
        var methodDetails: [MethodDetails] = []
        if !methodNames.isEmpty {
            methodDetails = extractMethodSignatures(
                fromFile: sourceFilePath,
                forClass: protocolCandidate,
                methodNames: methodNames
            )
            if methodDetails.count != methodNames.count {
                print("🔴 Не все методы найдены для \(protocolCandidate).")
            }
        }

        // 8) Собираем детали
        let protoName = "\(protocolCandidate)Protocol"
        let details = ProtocolExtractionDetails(
            name: protoName,
            methods: methodDetails,
            sourceClassName: protocolCandidate,
            dependentClassName: dependentClass,
            sourceFilePath: sourceFilePath,
            dependentFilePath: dependentFilePath
        )

        return RefactoringPlan(
            type: .extractProtocol,
            targetSCC: suggestion.component,
            protocolDetails: details
        )
    }

    // MARK: — Генерация кода протокола

    func generateProtocolCode(plan: RefactoringPlan) -> String? {
        guard case .extractProtocol = plan.type,
              let details = plan.protocolDetails
        else { return nil }

        // 1) Собираем список сигнатур из MethodDetails (убираем всё после '{')
        var signatures: [String] = details.methods.map { md in
            md.signature
                .components(separatedBy: "{")
                .first?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                ?? "func \(md.name)()"
        }

        // 2) Если ни одной сигнатуры не нашли — делаем fallback по regex по исходному файлу
        if signatures.isEmpty {
            if let source = try? String(contentsOf: URL(fileURLWithPath: details.sourceFilePath),
                                         encoding: .utf8) {
                let pattern = #"^\s*func\s+\w+\s*\([^)]*\)"#
                if let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) {
                    let ns = source as NSString
                    regex.enumerateMatches(in: source,
                                           options: [],
                                           range: NSRange(location: 0, length: ns.length)) { match, _, _ in
                        if let m = match {
                            let line = ns.substring(with: m.range).trimmingCharacters(in: .whitespaces)
                            signatures.append(line)
                        }
                    }
                }
            }
        }

        var code = "protocol \(details.name): AnyObject {\n"
        for sig in signatures {
            code += "    \(sig)\n"
        }
        code += "}\n"

        return code
    }

    // MARK: — Вставка протокола и модификация исходников

    /// 1) Вставляем protocol … в начало файла и добавляем `: ProtocolName` к объявлению класса
    func modifySourceClass(
        originalCode: String,
        plan: RefactoringPlan
    ) -> String? {
        guard case .extractProtocol = plan.type,
              let details   = plan.protocolDetails,
              let protoCode = generateProtocolCode(plan: plan)
        else { return nil }

        // Вставляем протокол перед всем остальным кодом (одна пустая строка)
        let withProtocol = protoCode + "\n" + originalCode

        // Парсим и добавляем `: ProtocolName` к объявлению класса
        let tree = Parser.parse(source: withProtocol)
        let rewriter = ProtocolConformanceRewriter(
            targetClassName: details.sourceClassName,
            protocolName: details.name
        )
        let modifiedTree = rewriter.rewrite(tree)

        // Форматируем в строку
        var result = modifiedTree.formatted().description

        // 1) Гарантируем ровно одну пустую строку после закрывающей `}` протокола
        result = result.replacingOccurrences(
            of: "}\\s*\\n{2,}",
            with: "}\n\n",
            options: .regularExpression
        )

        // 2) Убираем лишний пробел перед `:` в объявлении класса
        let className = details.sourceClassName
        let regex = #"class\s+\#(className)\s*:\s*"#   // матчит "class B   :  "
        let replacement = "class \(className): "
        result = result.replacingOccurrences(
            of: regex,
            with: replacement,
            options: .regularExpression
        )

        return result
    }

    /// 2) Заменяем в зависимом классе все `let x = SourceClass()` на `let x: SourceClassProtocol = SourceClass()`
    func modifyDependentClass(
        originalDependentCode: String,
        plan: RefactoringPlan
    ) -> String? {
        guard case .extractProtocol = plan.type,
              let details = plan.protocolDetails
        else { return nil }

        // Сначала синтаксический рерайт
        let tree = Parser.parse(source: originalDependentCode)
        let rewriter = DependentClassRewriter(
            targetClassName: details.dependentClassName,
            oldTypeName: details.sourceClassName,
            newTypeName: details.name
        )
        let modifiedTree = rewriter.rewrite(tree)
        var result = modifiedTree.formatted().description

        // Затем простая пост-обработка регексом:
        // из "let x = A()" делаем "let x: AProtocol = A()"
        let className = details.sourceClassName
        let protocolName = details.name
        let pattern = #"let\s+(\w+)\s*=\s*\#(className)\s*\(\s*\)"#
        let template = "let $1: \(protocolName) = \(className)()"
        result = result.replacingOccurrences(
            of: pattern,
            with: template,
            options: .regularExpression
        )

        return result
    }

    private func extractMethodSignatures(
        fromFile filePath: String,
        forClass className: String,
        methodNames: [String]
    ) -> [MethodDetails] {
        guard let source = try? String(contentsOf: URL(fileURLWithPath: filePath), encoding: .utf8) else {
            return []
        }
        let tree = Parser.parse(source: source)
        let extractor = MethodSignatureExtractor(
            targetClassName: className,
            targetMethodNames: Set(methodNames)
        )
        extractor.walk(tree)
        return extractor.extractedMethods.sorted(by: { $0.name < $1.name })
    }
}

