//
//  MethodDependencyCollector.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation
import SwiftSyntax

final class MethodDependencyCollector: SyntaxVisitor {
    private let filePath: String
    private let parentEntityName: String
    private var currentMethod: String?
    private var stack: [String] = []
    var entities: [MethodDependencyEntity] = []
    
    init(filePath: String, parentEntityName: String) {
        self.filePath = filePath
        self.parentEntityName = parentEntityName
        super.init(viewMode: .all)
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
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
    
    /// Когда видим MemberAccessExprSyntax, например: `other.someMethod()`
    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        guard let origin = currentMethod else { return .skipChildren }
        // node.name — имя вызываемого метода (String)
        let calledMethod = node.declName.baseName.text + "()"
        // Чтобы узнать, к какому классу/структуре относится «other», нам нужна информация о type of base expr.
        // На данном этапе мы упростим: будем считать, что если `other` — это локальная переменная класса X,
        // мы не сможем достоверно узнать X. Но если `other` — это имя класса (static) или self,
        // мы можем подставить parentEntityName или игнорировать.
        // Для простоты пока будем сохранять зависимость только в формате "?.\(calledMethod)".
        let dependency = calledMethod // или, при более сложном анализе, "SomeClass.\(calledMethod)"
        if let idx = entities.firstIndex(where: { $0.methodName == origin }) {
            entities[idx].dependencies.insert(dependency)
        }
        return .visitChildren
    }
    
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let origin = currentMethod else { return .skipChildren }
        // Node может быть "someMethod()" без области видимости.
        // В этом случае node.calledExpression.as(IdentifierExprSyntax.self)?.identifier.text даст имя функции.
        if let ident = node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text {
            let calledMethod = "\(ident)()"
            if let idx = entities.firstIndex(where: { $0.methodName == origin }) {
                entities[idx].dependencies.insert(calledMethod)
            }
        }
        return .visitChildren
    } 
}
