//
//  Analyzer.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 20.04.2025.
//

import Foundation

struct Analyzer {
    static func analyze(projectPath: String) -> String {
        var result = ""

        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: projectPath) else {
            return "❌ Не удалось прочитать директорию."
        }

        for case let file as String in enumerator {
            if file.hasSuffix(".swift") {
                let fullPath = (projectPath as NSString).appendingPathComponent(file)
                do {
                    let code = try String(contentsOfFile: fullPath)
                    result += analyzeFile(filename: file, content: code) + "\n"
                } catch {
                    result += "⚠️ Ошибка при чтении \(file)\n"
                }
            }
        }

        return result.isEmpty ? "✅ Проблем не найдено." : result
    }

    static func analyzeFile(filename: String, content: String) -> String {
        // Пример простого анализа
        if content.contains("Singleton") {
            return "🚨 \(filename): Найден Singleton — может мешать тестированию."
        } else {
            return "✅ \(filename): OK"
        }
    }
}
