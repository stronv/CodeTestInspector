//
//  CodeVisitor.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 20.04.2025.
//

import SwiftSyntax
import SwiftParser
import Foundation

final class CodeVisitor: SyntaxVisitor {
    var currentClassName: String = ""
    var propertyTypes: [String: String] = [:]
    var dependencies: [(origin: String, target: String)] = []

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        currentClassName = node.name.text
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        for binding in node.bindings {
            if let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
               let initializer = binding.initializer?.value.as(FunctionCallExprSyntax.self),
               let typeExpr = initializer.calledExpression.as(DeclReferenceExprSyntax.self) {

                propertyTypes[name] = typeExpr.baseName.text
                dependencies.append((origin: currentClassName, target: typeExpr.baseName.text))
            }
        }
        return .visitChildren
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        if let base = node.base?.as(DeclReferenceExprSyntax.self) {
            let accessedVariable = base.baseName.text
            if let resolvedType = propertyTypes[accessedVariable] {
                dependencies.append((origin: currentClassName, target: resolvedType))
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
//    func resolveType(from identifier: String) -> String {
//        let varName = identifier.components(separatedBy: ".").first ?? identifier
//        if let resolved = variableTypes[varName] {
//            return resolved.trimmed
//        }
//
//        return normalizeIdentifier(identifier)
//    }

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
