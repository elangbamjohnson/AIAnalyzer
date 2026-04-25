//
//  AnalyzerApp.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation
import SwiftParser

@main
struct AnalyzerApp {
    static func main() {
        
        guard CommandLine.arguments.count > 1 else {
            print("Usage: swift run AIAnalyzer <file.swift | folder>")
            exit(1)
        }
        
        let inputPath = CommandLine.arguments[1]
        let fullPath = URL(fileURLWithPath: inputPath).standardized.path
        
        var filePaths: [String] = []
        
        var isDirectory: ObjCBool = false
        
        if FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory),
           isDirectory.boolValue {
            
            print("📂 Scanning folder: \(fullPath)")
            filePaths = FileScanner.getSwiftFiles(in: fullPath)
            
        } else {
            filePaths = [fullPath]
        }
        
        if filePaths.isEmpty {
            print("⚠️ No Swift files found.")
            exit(0)
        }
        
        print("📊 Found \(filePaths.count) Swift files\n")
        
        // Initialize rule engine
        let engine = RuleEngine(rules: [
            LargeClassRule(),
            DataHeavyClassRule()
        ])
        
        // Process each file
        for filePath in filePaths {
            
            do {
                let source = try String(
                    contentsOf: URL(fileURLWithPath: filePath),
                    encoding: .utf8
                )
                
                let sourceFile = Parser.parse(source: source)
                
                let visitor = ClassVisitor(viewMode: .all)
                visitor.walk(sourceFile)
                
                let fileName = URL(fileURLWithPath: filePath).lastPathComponent
                
                print("\n📄 File: \(fileName)")
                print(String(repeating: "-", count: 40))
                
                // Print class details
                for classInfo in visitor.classes {
                    print("📦 Class: \(classInfo.name)")
                    print("   Methods: \(classInfo.methodCount)")
                    print("   Properties: \(classInfo.propertyCount)")
                    print("   Lines: \(classInfo.lineCount)\n")
                }
                
                // Analyze all classes in this file
                let issues = engine.analyze(visitor.classes)
                
                // Print issues
                for issue in issues {
                    print("   \(issue.severity.rawValue) \(issue.message)")
                }
                
            } catch {
                print("❌ Error reading file: \(filePath)")
                print("   \(error)")
            }
        }
    }
}
