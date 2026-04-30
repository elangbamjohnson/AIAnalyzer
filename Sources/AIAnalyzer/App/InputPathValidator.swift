//
//  InputPathValidator.swift
//  AIAnalyzer
//

import Foundation

enum InputPathValidator {
    static func singleFileExtensionError(for path: String, isDirectory: Bool) -> String? {
        guard !isDirectory else {
            return nil
        }

        let fileExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
        guard fileExtension == "swift" else {
            return "❌ Single-file input must be a .swift file"
        }

        return nil
    }
}
