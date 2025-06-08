//
//  MethodSignatureExtractor.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser

/// Helper class to extract full method signatures from a source file.
final class MethodSignatureExtractor: SyntaxVisitor {
    let targetClassName: String
    let targetMethodNames: Set<String>
    var currentClass: String?
    var extractedMethods: [MethodDetails] = []

    init(targetClassName: String, targetMethodNames: Set<String>) {
        self.targetClassName = targetClassName
        self.targetMethodNames = targetMethodNames
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.name.text == targetClassName {
            currentClass = node.name.text
            return .visitChildren
        }
        return .skipChildren
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        if node.name.text == targetClassName {
            currentClass = nil
        }
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard currentClass == targetClassName else { return .skipChildren }

        let methodName = node.name.text
        if targetMethodNames.contains(methodName) {
            let fullSignatureText = node.funcKeyword.text + node.signature.description
            extractedMethods.append(MethodDetails(name: methodName, signature: fullSignatureText.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        return .skipChildren
    }
}
