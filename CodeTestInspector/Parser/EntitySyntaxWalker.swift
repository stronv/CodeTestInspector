//
//  EntitySyntaxWalker.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 25.05.2025.
//

import Foundation
import SwiftSyntax

/// Парсинг AST и поиск нужных нам типов;
final class EntitySyntaxWalker: SyntaxVisitor {
    var entities: [ParsedEntity] = []
    let filePath: String
    
    init(filePath: String) {
        self.filePath = filePath
        super.init(viewMode: .all)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        entities.append(.init(name: node.name.text, type: .class, filePath: filePath))
        return .skipChildren
    }
    
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        entities.append(.init(name: node.name.text, type: .struct, filePath: filePath))
        return .skipChildren
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        entities.append(.init(name: node.name.text, type: .protocol, filePath: filePath))
        return .skipChildren
    }
}
