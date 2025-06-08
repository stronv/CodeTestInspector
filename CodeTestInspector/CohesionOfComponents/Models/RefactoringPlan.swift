//
//  RefactoringPlan.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

// Вспомогательные структуры для описания плана рефакторинга
struct RefactoringPlan {
    let type: PlanType
    let targetSCC: [String]
    let protocolDetails: ProtocolExtractionDetails?
}

extension RefactoringPlan {
    enum PlanType {
        case extractProtocol
    }
}
