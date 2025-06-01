//
//  ArchitectureAnalyzerScreen.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 28.05.2025.
//

import Foundation
import SwiftUI

struct ArchitectureAnalyzerScreen: View {
    @ObservedObject var viewModel: ArchitectureAnalyzerViewModel

    var body: some View {
        HStack(spacing: 0) {
            RuleEditorView(viewModel: viewModel)
                .frame(minWidth: 350)
                .padding()
                .background(Color(.windowBackgroundColor))

            Divider()

            ArchitectureAnalyzerView(viewModel: viewModel)
                .frame(minWidth: 350)
                .padding()
        }
    }
}
