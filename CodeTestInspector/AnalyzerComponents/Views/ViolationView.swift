//
//  ViolationView.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 20.04.2025.
//

import Foundation
import SwiftUI


import SwiftUI

struct ViolationView: View {
    let violation: Violation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🚫 \(violation.className)")
                .font(.headline)

            Text("📄 \(violation.filePath):\(violation.lineNumber)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("💡 \(violation.recommendation)")
                .font(.callout)
                .foregroundColor(.orange)

            ScrollView(.horizontal) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(snippetLines, id: \.0) { (index, line) in
                        Text(line)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(index == violation.lineNumber ? .white : .primary)
                            .padding(4)
                            .background(index == violation.lineNumber ? Color.red : Color.clear)
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            Button("Открыть файл") {
                openInXcode(path: violation.filePath)
            }
            .buttonStyle(BorderlessButtonStyle())

            Divider()
        }
        .padding(.vertical, 8)
    }

    /// Парсит сниппет построчно с указанием строки
    private var snippetLines: [(Int, String)] {
        let lines = violation.codeSnippet.components(separatedBy: .newlines)
        let startLine = violation.lineNumber - (lines.count / 2)
        return lines.enumerated().map { offset, line in
            (startLine + offset, line)
        }
    }

    private func openInXcode(path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(url)
    }
}
