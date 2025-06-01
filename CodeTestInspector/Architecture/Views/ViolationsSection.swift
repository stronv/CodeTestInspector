//
//  ViolationsSection.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 01.06.2025.
//

import Foundation
import SwiftUI

struct ViolationsSection: View {
    @ObservedObject var viewModel: ArchitectureAnalyzerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12, content: {
            if let _ = viewModel.selectedPath {
                if viewModel.violations.isEmpty {
                    Text("✅ Нарушений не найдено")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                } else {
                    Text("🚫 Нарушения:")
                        .font(.subheadline)
                        .bold()
                    
                    ForEach(viewModel.violations, id: \.fromClass) { violation in
                        ViolationRowView(violation: violation)
                    }
                }
            }
        })
    }
}
