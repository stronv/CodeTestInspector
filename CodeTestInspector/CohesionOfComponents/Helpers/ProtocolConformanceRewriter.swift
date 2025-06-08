//
//  ProtocolConformanceRewriter.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import SwiftSyntax
import SwiftSyntaxBuilder

final class ProtocolConformanceRewriter: SyntaxRewriter {
    let targetClassName: String
    let protocolName: String
    
    init(targetClassName: String, protocolName: String) {
        self.targetClassName = targetClassName
        self.protocolName = protocolName
    }
    
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        guard node.name.text == targetClassName else {
            return super.visit(node)
        }
        
        let newInheritedType = InheritedTypeSyntax(
            type: IdentifierTypeSyntax(name: .identifier(protocolName))
        )
        
        if var inheritanceClause = node.inheritanceClause {
            var inheritedTypes = inheritanceClause.inheritedTypes
            inheritedTypes.append(newInheritedType)
            inheritanceClause.inheritedTypes = inheritedTypes
            let modifiedClassDecl = node.with(\.inheritanceClause, inheritanceClause)
            return .init(modifiedClassDecl)
        } else {
            let newInheritanceClause = InheritanceClauseSyntax(
                colon: TokenSyntax(.colon, presence: .present),
                inheritedTypes: InheritedTypeListSyntax {
                    newInheritedType
                }
            )
            let modifiedClassDecl = node.with(\.inheritanceClause, newInheritanceClause)
            return .init(modifiedClassDecl)
        }
    }
}
