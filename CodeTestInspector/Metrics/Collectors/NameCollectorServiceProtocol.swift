//
//  NameCollectorServiceProtocol.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation

protocol NameCollectorServiceProtocol {
    func makeNameCollector() -> NameCollector
}

final class NameCollectorService: NameCollectorServiceProtocol {
    func makeNameCollector() -> NameCollector {
        return NameCollector(viewMode: .all)
    }
}
