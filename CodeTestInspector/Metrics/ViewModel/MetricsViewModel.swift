//
//  MetricsViewModel.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 01.06.2025.
//

import SwiftUI
import Combine

final class MetricsViewModel: ObservableObject {
    // 1) Путь к проекту, который выбирает пользователь
    @Published var selectedPath: URL? = nil
    
    // 2) Результат вычисления метрик
    @Published var metricsResult = MetricsResult()
    
    // 3) Флаг, что хотя бы раз мы запустили compute
    @Published var didCompute = false
    
    // 4) Сервис
    private let service: MetricsAnalysisServiceProtocol
    
    // Private properties
    // 5) Пороги для каждой метрики (нижняя и верхняя граница)
    //    Формат: (lower, upper)
    private let cyclomaticBounds: (Int, Int)             = (0, 50)
    private let maintainabilityBounds: (Double, Double)  = (20.0, 100.0)
    private let fanOutBounds: (Double, Double)           = (0.0, 1.0)
    private let depthBounds: (Int, Int)                  = (0, 5)
    private let couplingBounds: (Int, Int)               = (0, 100)
    
    
    init(service: MetricsAnalysisServiceProtocol = MetricsAnalysisService()) {
        self.service = service
    }
    
    // Метод, который вызывает сервис и сохраняет результат
    func computeMetrics() {
        guard let path = selectedPath else { return }
        let result = service.computeMetrics(at: path)
        DispatchQueue.main.async {
            self.metricsResult = result
            self.didCompute = true
        }
    }
}

extension MetricsViewModel {
    // public properties
    var isCyclomaticOutOfBounds: Bool {
        let value = metricsResult.totalCyclomatic
        return value < cyclomaticBounds.0 || value > cyclomaticBounds.1
    }

    var isMaintainabilityOutOfBounds: Bool {
        let value = metricsResult.maintainabilityIndex
        return value < maintainabilityBounds.0 || value > maintainabilityBounds.1
    }

    var isFanOutOutOfBounds: Bool {
        let value = metricsResult.fanOutSimilarity
        return value < fanOutBounds.0 || value > fanOutBounds.1
    }

    var isDepthOutOfBounds: Bool {
        let value = metricsResult.dependencyDepth
        return value < depthBounds.0 || value > depthBounds.1
    }

    var isCouplingOutOfBounds: Bool {
        let value = metricsResult.coupling
        return value < couplingBounds.0 || value > couplingBounds.1
    }
}
