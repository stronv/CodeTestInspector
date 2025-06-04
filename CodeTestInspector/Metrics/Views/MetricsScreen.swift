//
//  MetricsScreen.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 01.06.2025.
//

import Foundation
import SwiftUI

import SwiftUI

struct MetricsScreen: View {
    @ObservedObject var viewModel: MetricsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 1) Кнопка выбора папки
            HStack {
                Button("Выбрать проект") {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    panel.begin { resp in
                        guard resp == .OK, let url = panel.url else { return }
                        viewModel.selectedPath = url
                    }
                }
                .buttonStyle(.bordered)

                if let path = viewModel.selectedPath {
                    Text(path.path)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.leading, 4)
                }
            }

            // 2) Кнопка «Compute Metrics»
            Button {
                viewModel.computeMetrics()
            } label: {
                HStack {
                    Image(systemName: "chart.bar.fill")
                    Text("Рассчитать метрики")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedPath == nil)

            // 3) Если ещё не было вычислений — подсказка
            if !viewModel.didCompute {
                Text("Выберите проект и нажмите «Рассчитать метрики»")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.top, 8)
            }

            // 4) После вычисления — показываем результаты в виде списка
            if viewModel.didCompute {
                Divider().padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 8) {
                    // 4.1) Cyclomatic Complexity
                    HStack {
                        Text("🏷️ Cyclomatic Complexity:")
                            .bold()
                        Spacer()
                        Text("\(viewModel.metricsResult.totalCyclomatic)")
                            .foregroundColor(
                                viewModel.isCyclomaticOutOfBounds ? .red : .primary
                            )
                    }

                    // 4.2) Maintainability Index
                    HStack {
                        Text("📊 Maintainability Index:")
                            .bold()
                        Spacer()
                        Text(String(format: "%.1f", viewModel.metricsResult.maintainabilityIndex))
                            .foregroundColor(
                                viewModel.isMaintainabilityOutOfBounds ? .red : .primary
                            )
                    }

                    // 4.3) Fan-Out Similarity
                    HStack {
                        Text("🌐 Fan-Out Similarity:")
                            .bold()
                        Spacer()
                        Text(String(format: "%.2f", viewModel.metricsResult.fanOutSimilarity))
                            .foregroundColor(
                                viewModel.isFanOutOutOfBounds ? .red : .primary
                            )
                    }

                    // 4.4) Dependency Depth
                    HStack {
                        Text("📈 Dependency Depth:")
                            .bold()
                        Spacer()
                        Text("\(viewModel.metricsResult.dependencyDepth)")
                            .foregroundColor(
                                viewModel.isDepthOutOfBounds ? .red : .primary
                            )
                    }

                    // 4.5) Coupling
                    HStack {
                        Text("🔗 Coupling:")
                            .bold()
                        Spacer()
                        Text("\(viewModel.metricsResult.coupling)")
                            .foregroundColor(
                                viewModel.isCouplingOutOfBounds ? .red : .primary
                            )
                    }
                }
            }

            Spacer()
        }
        .padding(20)
        .frame(minWidth: 800, minHeight: 500)
    }
}
