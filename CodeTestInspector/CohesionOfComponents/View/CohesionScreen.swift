//
//  CohesionScreen.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation
import SwiftUI

import SwiftUI

struct CohesionScreen: View {
    @ObservedObject var viewModel: CohesionViewModel

    var body: some View {
        VStack(alignment: .leading) {
            // Кнопка выбора проекта
            HStack {
                Button("Выбрать проект") {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    panel.begin { resp in
                        guard resp == .OK, let url = panel.url else { return }
                        viewModel.computeCohesion(for: url)
                    }
                }
                .buttonStyle(.bordered)

                if let data = viewModel.cohesionData {
                    Text("Найдены \(data.largeSCCs.count) проблемных компонент(ы)")
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
            }
            .padding(.vertical, 10)

            Divider()

            // Основная область: если данные ещё не загружены
            if viewModel.cohesionData == nil {
                VStack {
                    Spacer()
                    Text("Выберите проект, чтобы начать анализ связности.")
                        .foregroundColor(.secondary)
                        .italic()
                    Spacer()
                }
            } else {
                // Данные есть — смотрим largeSCCs
                if let data = viewModel.cohesionData {
                    // Если нет ни одной «большой» (size>1) SCC, выводим сообщение «нет проблем»
                    if data.largeSCCs.isEmpty {
                        VStack {
                            Spacer()
                            Text("Проблемных файлов не выявлено — циклических зависимостей нет.")
                                .foregroundColor(.green)
                                .italic()
                            Spacer()
                        }
                    } else {
                        // Есть хотя бы одна проблема — показываем список
                        List {
                            Section(header: Text("Сильносвязанные компоненты (size > 1)")) {
                                ForEach(Array(data.largeSCCs.enumerated()), id: \.offset) { idx, component in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Компонента #\(idx + 1) (размер \(component.count)):")
                                            .font(.headline)
                                        ForEach(component, id: \.self) { node in
                                            // Убираем префиксы C: и M: при выводе
                                            if node.hasPrefix("C:") {
                                                Text("• Класс: \(node.dropFirst(2))")
                                                    .font(.caption)
                                            } else if node.hasPrefix("M:") {
                                                Text("• Метод: \(node.dropFirst(2))")
                                                    .font(.caption)
                                            } else {
                                                Text("• \(node)")
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }

                            // Если есть рекомендации – выводим их тоже
                            if !data.suggestions.isEmpty {
                                Section(header: Text("Рекомендации")) {
                                    ForEach(Array(data.suggestions.enumerated()), id: \.offset) { idx, sug in
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("🔧 Рекомендация #\(idx + 1):")
                                                .bold()
                                            Text(sug.message)
                                                .font(.body)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(20)
        .frame(minWidth: 800, minHeight: 500)
    }
}
