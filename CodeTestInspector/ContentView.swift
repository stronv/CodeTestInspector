//
//  ContentView.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 20.04.2025.
//

import SwiftUI
import AppKit

struct ContentView: View {
    var body: some View {
        AppDependencies.makeArchitectureAnalyzerModule()
            .frame(minWidth: 800, minHeight: 500)
    }
}

#Preview {
    ContentView()
}