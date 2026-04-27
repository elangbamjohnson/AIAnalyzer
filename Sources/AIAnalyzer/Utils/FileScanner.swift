//
//  FileScanner.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//

import Foundation

/// A utility for recursively discovering Swift source files within a directory.
struct FileScanner {
    
    /// Scans the specified directory and returns paths to all files with a `.swift` extension.
    /// - Parameter directory: The root directory path to start scanning from.
    /// - Returns: An array of full file paths to discovered Swift files.
    static func getSwiftFiles(in directory: String) -> [String] {
        let fileManager = FileManager.default
        var swiftFiles: [String] = []
        
        // Use an enumerator to recursively walk the directory tree
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
