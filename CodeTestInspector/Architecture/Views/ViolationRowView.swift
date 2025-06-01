//
//  ViolationRowView.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 01.06.2025.
//

import Foundation
import SwiftUI

struct ViolationRowView: View {
    let violation: ArchitectureViolation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4, content: {
            // 1. Заголовок с иконкой и названием класса/компонента
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(violation.fromClass)
                    .font(.headline)
                Text("(\(violation.fromComponent)) → \(violation.toComponent)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 2. Путь к файлу и номер строки
            HStack(spacing: 4) {
                Image(systemName: "doc.text")
                    .foregroundColor(.gray)
                Text("\(violation.filePath):\(violation.lineNumber ?? 0)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // 3. Горизонтальный сниппет с подсветкой строки
            ScrollView(.horizontal) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(violation.snippetLines, id: \.0) { (index, codeLine) in
                        Text(codeLine)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(index == violation.lineNumber ? .white : .primary)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 4)
                            .background(index == violation.lineNumber
                                        ? Color.red.opacity(0.8)
                                        : Color.clear)
                            .cornerRadius(2)
                            // Здесь каждая строка занимает свою «ячейку» в VStack
                    }
                }
            }
            .frame(maxHeight: 120)

            Divider()
        })
        .padding(.bottom, 8)
    }
}
