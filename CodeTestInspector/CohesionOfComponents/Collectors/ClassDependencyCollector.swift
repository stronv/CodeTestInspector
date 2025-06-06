//
//  ClassDependencyCollector.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation
import SwiftSyntax

final class ClassDependencyCollector: SyntaxVisitor {
    // Properties
    private let filePath: String
    private var stack: [String] = []
    let allNames: Set<String>
    var entities: [ClassDependencyEntity] = []
    
    // MARK: - Initialization
    init(allNames: Set<String>, filePath: String) {
        self.allNames = allNames
        self.filePath = filePath
        super.init(viewMode: .all)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text
        entities.append(.init(name: name, dependencies: [], filePath: filePath))
        stack.append(name)
        return .visitChildren
    }
    
    override func visitPost(_ node: ClassDeclSyntax) {
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
    
    // 1) var foo: SomeType, func bar(x: SomeType) и т.п.
    override func visit(_ node: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
        guard let origin = stack.last else { return .skipChildren }
        let used = node.name.text
        if allNames.contains(used),
           let idx = entities.firstIndex(where: { $0.name == origin }) {
            entities[idx].dependencies.insert(used)
        }
        return .visitChildren
    }

    // 2) Наследование: class A: B, C, struct S<T: U> { … }
    override func visit(_ node: InheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
        guard let origin = stack.last else { return .skipChildren }
        for element in node.inheritedTypes {
            let used = element.type.description
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if allNames.contains(used),
               let idx = entities.firstIndex(where: { $0.name == origin }) {
                entities[idx].dependencies.insert(used)
            }
        }
        return .skipChildren
    }
    
    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        guard let origin = stack.last else { return .skipChildren }
        let used = node.baseName.text
        if allNames.contains(used),
           let idx = entities.firstIndex(where: { $0.name == origin }) {
            entities[idx].dependencies.insert(used)
        }
        return .visitChildren
    }

    // 4) Module.TypeName (MemberTypeSyntax)
    override func visit(_ node: MemberTypeSyntax) -> SyntaxVisitorContinueKind {
        guard let origin = stack.last else { return .skipChildren }
        let used = node.name.text
        if allNames.contains(used),
           let idx = entities.firstIndex(where: { $0.name == origin }) {
            entities[idx].dependencies.insert(used)
        }
        return .visitChildren
    }
}
