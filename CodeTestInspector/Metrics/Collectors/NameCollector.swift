//
//  NameCollector.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 02.06.2025.
//

import Foundation
import SwiftSyntax

/// Первый проход: собираем только имена всех классов/структур/протоколов
final class NameCollector: SyntaxVisitor {
    /// Все встреченные имена entity (класс, структура, протокол)
    var names: Set<String> = []

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        names.insert(node.name.text)
        return .skipChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        names.insert(node.name.text)
        return .skipChildren
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        names.insert(node.name.text)
        return .skipChildren
    }
}
