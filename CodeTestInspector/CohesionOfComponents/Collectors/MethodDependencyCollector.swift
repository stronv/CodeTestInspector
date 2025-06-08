//
//  MethodDependencyCollector.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation
import SwiftSyntax

/// Собирает зависимости на уровне методов внутри конкретного класса.
final class MethodDependencyCollector: SyntaxVisitor {
    private let filePath: String
    private let parentEntityName: String
    private var currentMethod: String?
    var entities: [MethodDependencyEntity] = []

    init(filePath: String, parentEntityName: String) {
        self.filePath = filePath
        self.parentEntityName = parentEntityName
        super.init(viewMode: .all)
    }

    // MARK: — Когда входим в FunctionDeclSyntax (метод), сбрасываем текущий метод
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        // Составляем имя метода вида "B.bar()"
        let methodName = "\(parentEntityName).\(node.name.text)()"
        entities.append(.init(
            parentEntityName: parentEntityName,
            methodName: methodName,
            dependencies: [],
            filePath: filePath
        ))
        currentMethod = methodName
        return .visitChildren
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        currentMethod = nil
    }

    // MARK: — Когда видим вызов вида `something.bar()`
    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        guard let origin = currentMethod else {
            return .skipChildren
        }
        // Имя вызываемого метода, например "bar()"
        let calledMethodName = node.declName.baseName.text + "()"

        // Попытаемся понять, к какому классу относится `node.base`
        // Если base — это идентификатор, совпадающий с именем класса (например, B), берем "B.bar()".
        var dependencyKey: String
        if let baseIdent = node.base?.as(DeclReferenceExprSyntax.self)?.baseName.text,
           baseIdent == parentEntityName {
            dependencyKey = "\(parentEntityName).\(calledMethodName)"
        } else {
            dependencyKey = "\(parentEntityName).\(calledMethodName)"
        }

        // Добавляем в зависимости для текущего метода
        if let idx = entities.firstIndex(where: { $0.methodName == origin }) {
            entities[idx].dependencies.insert(dependencyKey)
        }
        return .visitChildren
    }

    // MARK: — Если просто FunctionCall без области видимости, тоже считаем, что метод из текущего класса
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let origin = currentMethod else {
            return .skipChildren
        }
        if let ident = node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text {
            // Напрямую вызывают bar(), создание экземпляров и т.п.
            let called = "\(ident)()"
            let dependencyKey = "\(parentEntityName).\(called)"
            if let idx = entities.firstIndex(where: { $0.methodName == origin }) {
                entities[idx].dependencies.insert(dependencyKey)
            }
        }
        return .visitChildren
    }
}
