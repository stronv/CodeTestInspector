//
//  ProtocolExtractionDetails.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 04.06.2025.
//

import Foundation

struct ProtocolExtractionDetails {
    let name: String
    let methods: [MethodDetails]
    let sourceClassName: String
    let dependentClassName: String
    let sourceFilePath: String
    let dependentFilePath: String
}
