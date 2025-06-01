//
//  ComponentRule.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 20.04.2025.
//

import Foundation

struct ComponentRule: Codable {
    let component: String
    let allowedDependencies: [String]
}
