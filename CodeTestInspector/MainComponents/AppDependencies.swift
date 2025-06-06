//
//  AppDependencies.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 28.05.2025.
//

import Foundation
import SwiftUI

final class AppDependencies {
    static func makeArchitectureAnalyzerModule() -> some View {
        let viewModel = ArchitectureAnalyzerViewModel()
        return ArchitectureAnalyzerScreen(viewModel: viewModel)
    }
    
    static func makeMetricsModule() -> some View {
        let viewModel = MetricsViewModel()
        return MetricsScreen(viewModel: viewModel)
    }
    
    static func makeCohesionModule() -> some View {
        let viewModel = CohesionViewModel()
        return CohesionScreen(viewModel: viewModel)
    }
}
