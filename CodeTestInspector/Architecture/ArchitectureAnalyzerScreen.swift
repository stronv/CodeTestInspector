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
        ZStack {
            Color(.controlBackgroundColor)
                .ignoresSafeArea(.all)
            ScrollView {
                VStack(alignment: .leading, spacing: 20, content: {
                    RulesSection(ruleManager: viewModel.ruleManager)

                    Divider()

                    PathAndAnalyzeSection(viewModel: viewModel)
                    
                    Divider()
                    
                    ViolationsSection(viewModel: viewModel)
                    
                    Spacer()
                })
                .padding(20)
            }
        }
    }
}
