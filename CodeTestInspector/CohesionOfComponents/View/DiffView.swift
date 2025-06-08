//
//  DiffView.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 07.06.2025.
//

import Foundation
import SwiftUI

struct DiffView: View {
    let diffLines: [DiffLine]

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(diffLines) { line in
                    HStack(alignment: .top, spacing: 4) {
                        // Prefix: + или –
                        Text(symbol(for: line.type))
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 20, alignment: .leading)

                        Text(line.text)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(foregroundColor(for: line.type))
                    }
                    .padding(.vertical, 1)
                    .background(backgroundColor(for: line.type))
                }
            }
            .padding(4)
        }
        .border(Color.gray.opacity(0.3), width: 1)
    }
}

private extension DiffView {
    func symbol(for type: DiffLineType) -> String {
        switch type {
        case .added:   return "+"
        case .removed: return "−"
        }
    }

    func foregroundColor(for type: DiffLineType) -> Color {
        switch type {
        case .added:   return .green
        case .removed: return .red
        }
    }

    func backgroundColor(for type: DiffLineType) -> Color {
        switch type {
        case .added:   return Color.green.opacity(0.1)
        case .removed: return Color.red.opacity(0.1)
        }
    }
}
