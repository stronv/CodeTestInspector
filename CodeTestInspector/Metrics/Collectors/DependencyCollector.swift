//
//  DependencyCollector.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 02.06.2025.
//

import Foundation
import SwiftSyntax

/// Второй проход: собираем зависимости между сущностями, зная полный набор имён
final class DependencyCollector: SyntaxVisitor {
    // Набор всех имён entity, собранный NameCollector-ом
    let allNames: Set<String>
    
    /// Собранные сущности вместе с их зависимостями
    var entities: [ParsedMetricEntity] = []
    
    private let filePath: String
    /// Стек, в котором в любой момент хранится «текущая» сущность (самый верхний элемент)
    private var stack: [String] = []
    
    init(allNames: Set<String>, filePath: String) {
        self.allNames = allNames
        self.filePath = filePath
        super.init(viewMode: .all)
    }
    
    // MARK: — Обработка объявлений entity
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text
        // Регистрируем новую сущность (с пустым множеством зависимостей пока)
        entities.append(.init(name: name, dependencies: [], filePath: filePath))
        // Пушим в стек, чтобы последующие узлы внутри класса «приписывались» к нему
        stack.append(name)
        return .visitChildren
    }
    
    override func visitPost(_ node: ClassDeclSyntax) {
        // Когда вышли из тела класса — убираем из стека
        stack.removeLast()
    }
    
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text
        entities.append(.init(name: name, dependencies: [], filePath: filePath))
        stack.append(name)
        return .visitChildren
    }
    
    override func visitPost(_ node: StructDeclSyntax) {
        stack.removeLast()
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text
        entities.append(.init(name: name, dependencies: [], filePath: filePath))
        stack.append(name)
        return .visitChildren
    }
    
    override func visitPost(_ node: ProtocolDeclSyntax) {
        stack.removeLast()
    }
    
    // MARK: — Ловим зависимости
    
    /// 1. Типы в аннотациях: var user: User или init(user: User)
    override func visit(_ node: TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
        // Если нет «текущей» сущности в стеке — пропускаем
        guard let origin = stack.last else { return .skipChildren }
        
        // node.type может быть, например, SimpleTypeIdentifierSyntax("User")
        if let simple = node.type.as(IdentifierTypeSyntax.self) {
            let usedName = simple.name.text
            if allNames.contains(usedName),
               let idx = entities.firstIndex(where: { $0.name == origin }) {
                entities[idx].dependencies.insert(usedName)
            }
        }
        return .visitChildren
    }
    
    /// 2. Наследование и generic-ограничения:
    /// class A: B, C { … }, struct S<T: U> { … }
    override func visit(_ node: InheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
        guard let origin = stack.last else { return .skipChildren }
        for element in node.inheritedTypes {
            let usedName = element.type.description
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if allNames.contains(usedName),
               let idx = entities.firstIndex(where: { $0.name == origin }) {
                entities[idx].dependencies.insert(usedName)
            }
        }
        return .skipChildren
    }
    
    /// 3. Прямые обращения к сущности (например, вызов конструктора UserView())
    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        guard let origin = stack.last else { return .skipChildren }
        let usedName = node.identifier.text
        if allNames.contains(usedName),
           let idx = entities.firstIndex(where: { $0.name == origin }) {
            entities[idx].dependencies.insert(usedName)
        }
        return .visitChildren
    }
}
