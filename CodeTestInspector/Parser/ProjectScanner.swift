//
//  ProjectScanner.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 25.05.2025.
//

import Foundation

protocol ProjectScannerProtocol {
    func scan(at path: URL) -> [URL]
}

final class ProjectScanner: ProjectScannerProtocol {
    func scan(at path: URL) -> [URL] {
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: path, includingPropertiesForKeys: nil)
        var swiftFiles: [URL] = []
        
        while let file = enumerator?.nextObject() as? URL {
            if file.pathExtension == "swift" {
                swiftFiles.append(file)
            }
        }
        return swiftFiles
    }
}
