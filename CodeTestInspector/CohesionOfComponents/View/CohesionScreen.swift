//
//  CohesionScreen.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation
import SwiftUI

struct CohesionScreen: View {
    @ObservedObject var viewModel: CohesionViewModel

    var body: some View {
        VStack(alignment: .leading) {
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
                    Text("Найдено \(data.largeSCCs.count) проблемных компонент(ы). Предложено \(data.refactoringPlans.count) план(ов) рефакторинга.")
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
            }
            .padding(.vertical, 10)

            Divider()

            if viewModel.cohesionData == nil {
                VStack {
                    Spacer()
                    Text("Выберите проект, чтобы начать анализ связности.")
                        .foregroundColor(.secondary)
                        .italic()
                    Spacer()
                }
            } else if let data = viewModel.cohesionData {
                if data.largeSCCs.isEmpty && data.refactoringPlans.isEmpty {
                    VStack {
                        Spacer()
                        Text("Проблемных файлов не выявлено — циклических зависимостей нет. Планов рефакторинга нет.")
                            .foregroundColor(.green)
                            .italic()
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Секция сильносвязанных компонент
                            if !data.largeSCCs.isEmpty {
                                Text("Сильносвязанные компоненты (size > 1)")
                                    .font(.headline)
                                ForEach(Array(data.largeSCCs.enumerated()), id: \.offset) { idx, component in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Компонента #\(idx + 1) (размер \(component.count)):")
                                            .font(.subheadline).bold()
                                        ForEach(component, id: \.self) { node in
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

                            // Секция рекомендаций
                            if !data.suggestions.isEmpty {
                                Text("Рекомендации")
                                    .font(.headline)
                                ForEach(Array(data.suggestions.enumerated()), id: \.offset) { idx, sug in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("🔧 Рекомендация #\(idx + 1):")
                                            .font(.subheadline).bold()
                                        Text(sug.message)
                                            .font(.body)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }

                            // Секция планов рефакторинга
                            if !data.refactoringPlans.isEmpty {
                                Text("Планы рефакторинга")
                                    .font(.headline)
                                let plansArray = data.refactoringPlans.sorted(by: { $0.key < $1.key })
                                ForEach(plansArray, id: \.key) { sccIdentifier, plan in
                                    VStack(alignment: .leading, spacing: 4) {
                                        if case .extractProtocol = plan.type, let details = plan.protocolDetails {
                                            Text("🛠️ Извлечь протокол '\(details.name)'")
                                                .font(.subheadline).bold()
                                            Text("   • Из класса: \(details.sourceClassName)")
                                            Text("   • Для зависимого класса: \(details.dependentClassName)")
                                            Text("   • SCC: \(sccIdentifier)")
                                                .font(.caption)
                                                .foregroundColor(.gray)

                                            Button("Применить (preview изменений)") {
                                                viewModel.applyRefactoringPlan(plan)
                                            }
                                            .padding(.top, 5)
                                        } else {
                                            Text("Неизвестный план рефакторинга")
                                        }
                                    }
                                    .padding(.vertical, 6)
                                }
                            }

                            if !viewModel.codeDiffs.isEmpty {
                                Divider().padding(.vertical, 8)
                                Text("Предпросмотр изменений:")
                                    .font(.headline)

                                ForEach(viewModel.codeDiffs, id: \.filePath) { section in
                                    Text(section.filePath)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)

                                    DiffView(diffLines: section.lines)
                                        .frame(maxHeight: 200)
                                }

                                Button("Сохранить изменения") {
                                    viewModel.saveRefactoringChanges()
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }

            Spacer()
        }
        .padding(20)
        .frame(minWidth: 800, minHeight: 600)
    }
}
