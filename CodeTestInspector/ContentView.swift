//
//  ContentView.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 20.04.2025.
//

import SwiftUI
import SwiftSyntax
import SwiftParser

struct ContentView: View {
    @State private var selectedAnalysis: AnalysisType = .architecture
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedAnalysis) {
                ForEach(AnalysisType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding([.top, .horizontal], 12)
            
            Divider()

            Group {
                switch selectedAnalysis {
                case .architecture:
                    AppDependencies.makeArchitectureAnalyzerModule()
                case .metrics:
                    AppDependencies.makeMetricsModule()
                case .connectivity:
                    AppDependencies.makeCohesionModule()
                }
            }
            .frame(minWidth: 800, minHeight: 500)
        }
    }
}

#Preview {
    ContentView()
}
