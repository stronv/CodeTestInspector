//
//  EntityDependencyVisitor.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 01.06.2025.
//

import Foundation
import SwiftSyntax

/// Структура, которая представляет одну сущность и её зависимости
struct ParsedMetricEntity {
    let name: String
    var dependencies: Set<String> // Имена классов/структур, упомянутые внутри тела
    let filePath: String
}

/// Собирает все классы/структуры/протоколы и то, какие другие типы они используют
final class EntityDependencyVisitor: SyntaxVisitor {
    var entities: [ParsedMetricEntity] = []
    private let filePath: String
    private var currentEntityName: String? = nil
    
    // Это вычислим после полного посещения узла, либо поддерживаем актуальный set «в поле»
    private var allNames: Set<String> {
        Set(entities.map { $0.name })
    }

    init(filePath: String) {
        self.filePath = filePath
        super.init(viewMode: .all)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text
        let entity = ParsedMetricEntity(name: name, dependencies: [], filePath: filePath)
        entities.append(entity)
        currentEntityName = name
        return .visitChildren
    }
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text
        let entity = ParsedMetricEntity(name: name, dependencies: [], filePath: filePath)
        entities.append(entity)
        currentEntityName = name
        return .visitChildren
    }
    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text
        let entity = ParsedMetricEntity(name: name, dependencies: [], filePath: filePath)
        entities.append(entity)
        currentEntityName = name
        return .visitChildren
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        if node.name.text == currentEntityName {
            currentEntityName = nil
        }
    }
    override func visitPost(_ node: StructDeclSyntax) {
        if node.name.text == currentEntityName {
            currentEntityName = nil
        }
    }
    override func visitPost(_ node: ProtocolDeclSyntax) {
        if node.name.text == currentEntityName {
            currentEntityName = nil
        }
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        guard let origin = currentEntityName else {
            return .skipChildren
        }
        let usedName = node.baseName.text

        // Добавляем зависимость ТОЛЬКО если это «непосредственно» одна из наших сущностей
        if allNames.contains(usedName) {
            if let idx = entities.firstIndex(where: { $0.name == origin }) {
                entities[idx].dependencies.insert(usedName)
            }
        }
        return .visitChildren
    }
}
