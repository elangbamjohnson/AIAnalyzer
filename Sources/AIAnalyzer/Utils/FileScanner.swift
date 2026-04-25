//
//  FileScanner.swift
//  AIAnalyzer
//
//  Created by Johnson on 25/04/26.
//

import Foundation

struct FileScanner {
    
    static func getSwiftFiles(in directory: String) -> [String] {
        let fileManager = FileManager.default
        var swiftFiles: [String] = []
        
        if let enumerator = fileManager.enumerator(atPath: directory) {
            for case let file as String in enumerator {
                if file.hasSuffix(".swift") {
                    let fullPath = (directory as NSString).appendingPathComponent(file)
                    swiftFiles.append(fullPath)
                }
            }
        }
        
        return swiftFiles
    }
}
