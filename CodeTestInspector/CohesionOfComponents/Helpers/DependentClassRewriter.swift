//
//  DependentClassRewriter.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation
import SwiftSyntax

class DependentClassRewriter: SyntaxRewriter {
    let targetClassName: String
    let oldTypeName: String
    let newTypeName: String

    init(targetClassName: String, oldTypeName: String, newTypeName: String) {
        self.targetClassName = targetClassName
        self.oldTypeName = oldTypeName
        self.newTypeName = newTypeName
    }

    // MARK: – Посещение объявления класса
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        // У ClassDeclSyntax имя хранится в node.identifier
        guard node.name.text == targetClassName else {
            return DeclSyntax(super.visit(node))
        }
        // Если это нужный класс — обходим его содержимое, но не меняем сам заголовок
        return DeclSyntax(super.visit(node))
    }

    // MARK: – Посещение объявления переменной (VariableDeclSyntax)
    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        // Поскольку node.bindings — это PatternBindingListSyntax
        if let firstBinding = node.bindings.first,
           let typeAnnotation = firstBinding.typeAnnotation {
            if let identifierType = typeAnnotation.type.as(IdentifierTypeSyntax.self),
               identifierType.name.text == oldTypeName {

                // Создаём новый IdentifierTypeSyntax с именем протокола
                let newTypeSyntax = IdentifierTypeSyntax(name: .identifier(newTypeName))
                let newTypeAnnotation = typeAnnotation.with(\.type, TypeSyntax(newTypeSyntax))
                let newBinding = firstBinding.with(\.typeAnnotation, newTypeAnnotation)

                // Собираем новый список биндингов (PatternBindingListSyntax) из одного элемента
                let newBindingsList = PatternBindingListSyntax([newBinding])
                let modifiedNode = node.with(\.bindings, newBindingsList)
                return DeclSyntax(modifiedNode)
            }
        }
        return DeclSyntax(super.visit(node))
    }

    // MARK: – Посещение параметра функции (FunctionParameterSyntax)
    override func visit(_ node: FunctionParameterSyntax) -> FunctionParameterSyntax {
        // Теперь node.type — это не Optional, а TypeSyntax
        let typeSyntax = node.type
        if let identifierType = typeSyntax.as(IdentifierTypeSyntax.self),
           identifierType.name.text == oldTypeName {

            // Создаём новый IdentifierTypeSyntax с именем протокола
            let newTypeSyntax = IdentifierTypeSyntax(name: .identifier(newTypeName))
            let modifiedNode = node.with(\.type, TypeSyntax(newTypeSyntax))
            return modifiedNode
        }
        // Идём дальше по дереву
        let visited = super.visit(node)
        // super.visit(node) возвращает 'Syntax', поэтому приводим его обратно
        return visited.as(FunctionParameterSyntax.self) ?? node
    }
}
