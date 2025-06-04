//
//  ContentView.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 20.04.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedAnalysis: AnalysisType = .architecture
    
    var body: some View {
        VStack(spacing: 0) {
            // 1) Сегмент для выбора типа анализа
            Picker("", selection: $selectedAnalysis) {
                ForEach(AnalysisType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding([.top, .horizontal], 12)
            
            Divider()

            // 2) Внизу — динамический контент:
            //    если выбран .architecture, показываем экран архитектуры,
            //    если .metrics, — экран метрик.
            Group {
                switch selectedAnalysis {
                case .architecture:
                    AppDependencies.makeArchitectureAnalyzerModule()
                case .metrics:
                    AppDependencies.makeMetricsModule()
                }
            }
            .frame(minWidth: 800, minHeight: 500)
        }
    }
}

#Preview {
    ContentView()
}
