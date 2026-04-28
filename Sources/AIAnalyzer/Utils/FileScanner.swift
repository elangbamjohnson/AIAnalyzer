//
//  FileScanner.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//

import Foundation

/// A utility for recursively discovering Swift source files within a directory.
struct FileScanner {
    
/// A utility for recursively discovering Swift source files within a directory.
struct FileScanner {
    
    private static let ignoredDirectories: Set<String> = [
        ".build",
        ".git",
        ".swiftpm",
        "DerivedData",
        "Pods",
        "Build",
        "Carthage"
    ]
    
    static func getSwiftFiles(in directory: String) -> [String] {
        
        let fileManager = FileManager.default
        var swiftFiles: [String] = []
        
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: directory),
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        for case let fileURL as URL in enumerator {
            
            let path = fileURL.path
            
            // 🔴 Skip ignored directories and their contents
            if shouldIgnore(path: path) {
                enumerator.skipDescendants()
                continue
            }
            
            // ✅ Only collect Swift files
            if path.hasSuffix(".swift") {
                swiftFiles.append(path)
            }
        }
        
        return swiftFiles
    }
    
    private static func shouldIgnore(path: String) -> Bool {
        let components = URL(fileURLWithPath: path).pathComponents
        // If any component of the path is in our ignore list, skip it
        return !Set(components).isDisjoint(with: ignoredDirectories)
    }
}
