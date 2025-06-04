//
//  CyclomaticComplexityVisitor.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 01.06.2025.
//

import Foundation
import SwiftSyntax

/// Хранит результат для одной функции: её имя, lcoation и CC
struct FunctionComplexity {
    let name: String
    let complexity: Int
    let filePath: String
    let line: Int
    let column: Int
}

/// Собирает цикломатическую сложность для каждой функции (метода, init, subscript и т. д.)
final class CyclomaticComplexityVisitor: SyntaxVisitor {
    // MARK: — Внешний API
    
    /// Прямой результат: набор структур с именем функции, путём, локацией и CC
    var functionComplexities: [FunctionComplexity] = []
    
    // MARK: — Внутреннее состояние
    
    /// По RFC каждая функция начинается с 1
    private var currentComplexity = 1
    /// Путь к файлу, чтобы сохранять в результат
    private let filePath: String
    /// Конвертер, чтобы получать номер строки/колонку из Syntax
    private let locationConverter: SourceLocationConverter
    
    init(filePath: String, locationConverter: SourceLocationConverter) {
        self.filePath = filePath
        self.locationConverter = locationConverter
        super.init(viewMode: .all)
    }

    // MARK: — Обработка объявления функции
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        // Сохраним старую сложность (для вложенных функций)
        let previousComplexity = currentComplexity
        // Переключаемся на новую функцию
        currentComplexity = 1
        
        // Если есть тело, «прогуляемся» по нему — все decision points ухватятся в override-ах ниже
        if let body = node.body {
            walk(body)
        }
        
        // Сохраняем результат
        let name = node.name.text
        let loc  = node.startLocation(converter: locationConverter)
        
        functionComplexities.append(.init(
            name: name,
            complexity: currentComplexity,
            filePath: filePath,
            line: loc.line,
            column: loc.column
        ))
        
        // Восстанавливаем предыдущую сложность (пенант вложенной функции)
        currentComplexity = previousComplexity
        // .skipChildren, чтобы не ходить повторно по body, мы уже всё сделали через walk(body)
        return .skipChildren
    }
    
    // MARK: — Decision Points
    
    /// Обычный if ... { ... }
    override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
        currentComplexity += 1
        return .visitChildren
    }
    
    /// switch ... { case ...: ... }
    override func visit(_ node: SwitchExprSyntax) -> SyntaxVisitorContinueKind {
        // +1 за каждый case/default
        let caseCount = node.cases.count
        currentComplexity += caseCount
        return .visitChildren
    }
    
    /// for x in collection { ... }
    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        currentComplexity += 1
        return .visitChildren
    }
    
    /// while condition { ... }
    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        currentComplexity += 1
        return .visitChildren
    }
    
    /// repeat { ... } while condition
    override func visit(_ node: RepeatStmtSyntax) -> SyntaxVisitorContinueKind {
        currentComplexity += 1
        return .visitChildren
    }
    
    /// guard condition else { ... }
    override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
        currentComplexity += 1
        return .visitChildren
    }
    
    /// catch { ... } после do { ... } catch { ... }
    override func visit(_ node: CatchClauseSyntax) -> SyntaxVisitorContinueKind {
        currentComplexity += 1
        return .visitChildren
    }
    
    /// Тернарный оператор ?:
    override func visit(_ node: TernaryExprSyntax) -> SyntaxVisitorContinueKind {
        currentComplexity += 1
        return .visitChildren
    }
    
    /// Логические операторы && и || в условиях (каждый +1)
    override func visit(_ node: BinaryOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        let op = node.operator.text.trimmingCharacters(in: .whitespaces)
        if op == "&&" || op == "||" {
            currentComplexity += 1
        }
        return .visitChildren
    }
    
    /// (Можно оставить, если вам ещё нужны «if как выражение» или другие ConditionElement)
    override func visit(_ node: ConditionElementSyntax) -> SyntaxVisitorContinueKind {
        // Обычно сюда попадают конструкции вида `if let x = …, y == …`.
        // Каждый такой «элемент» тоже считают +1 к CC.
        currentComplexity += 1
        return .visitChildren
    }
}
