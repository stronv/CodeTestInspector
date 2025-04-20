//
//  CodeVisitor.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 20.04.2025.
//

import SwiftSyntax
import SwiftParser
import Foundation

class CodeVisitor: SyntaxVisitor {
    var imports: [String] = []
    var methodCalls: [(origin: String, target: String)] = []
    var propertyAccesses: [(origin: String, target: String)] = []

    private var currentClassStack: [String] = []
    private var variableTypes: [String: String] = [:] // Новое: varName -> Type

    override public func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let className = node.name.text.trimmed
        currentClassStack.append(className)
        return .visitChildren
    }

    override public func visitPost(_ node: ClassDeclSyntax) {
        currentClassStack.popLast()
    }

    override public func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        let path = node.path.description.trimmed
        imports.append(path)
        return .visitChildren
    }

    override public func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let methodCall = node.calledExpression.description.trimmed
        if let currentClass = currentClassStack.last {
            let resolvedTarget = resolveType(from: methodCall)
            methodCalls.append((origin: currentClass, target: resolvedTarget))
        }
        return .visitChildren
    }

    override public func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        if let base = node.base?.description.trimmed,
           let currentClass = currentClassStack.last {
            let resolvedBase = resolveType(from: base)
            propertyAccesses.append((origin: currentClass, target: resolvedBase))
        }
        return .visitChildren
    }

    override public func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        for binding in node.bindings {
            guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { continue }

            // Попытка определить тип явно
            if let typeAnnotation = binding.typeAnnotation?.type.description.trimmed {
                variableTypes[identifier] = typeAnnotation
            }
            // Или по инициализации: var model = UserModel()
            else if let initializer = binding.initializer?.value.as(FunctionCallExprSyntax.self) {
                let typeName = initializer.calledExpression.description.trimmed
                variableTypes[identifier] = typeName
            }
        }
        return .visitChildren
    }
}


extension String {
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension CodeVisitor {
    func resolveType(from identifier: String) -> String {
        let varName = identifier.components(separatedBy: ".").first ?? identifier
        if let resolved = variableTypes[varName] {
            return resolved.trimmed
        }

        return normalizeIdentifier(identifier)
    }

    func normalizeIdentifier(_ identifier: String) -> String {
        return identifier
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "!", with: "")
            .replacingOccurrences(of: "()", with: "")
            .components(separatedBy: CharacterSet(charactersIn: ".(")).first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? identifier
    }
}

private extension CodeParser {
    func extractClassName(from identifier: String) -> String {
        identifier
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "!", with: "")
            .replacingOccurrences(of: "()", with: "")
            .components(separatedBy: CharacterSet(charactersIn: ".(")).first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? identifier
    }
}
