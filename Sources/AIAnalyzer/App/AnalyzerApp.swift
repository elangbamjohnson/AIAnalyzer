//
//  AnalyzerApp.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation
import SwiftParser

/// The main entry point for the AIAnalyzer command-line tool.
@main
struct AnalyzerApp {
    /// Orchestrates the entire analysis lifecycle: CLI input parsing, file discovery, 
    /// syntax visitation, rule evaluation, and final reporting.
    static func main() {
        
        // Validate that a file or folder path was provided as a command-line argument
        guard CommandLine.arguments.count > 1 else {
            print("Usage: swift run AIAnalyzer <file.swift | folder>")
            exit(1)
        }
        
        let inputPath = CommandLine.arguments[1]
        let fullPath = URL(fileURLWithPath: inputPath).standardized.path
        
        var filePaths: [String] = []
        var isDirectory: ObjCBool = false
        
        // Determine if the input path is a directory or a single file
        if FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory),
           isDirectory.boolValue {
            print("📂 Scanning folder: \(fullPath)")
            filePaths = FileScanner.getSwiftFiles(in: fullPath)
        } else {
            filePaths = [fullPath]
        }
        
        // Exit early if no analysis targets are found
        if filePaths.isEmpty {
            print("⚠️ No Swift files found.")
            exit(0)
        }
        
        print("📊 Found \(filePaths.count) Swift files\n")
        
        // Initialize the rule engine with predefined rules and thresholds
        let engine = RuleEngine(rules: [
            LargeClassRule(threshold: 10),
            DataHeavyClassRule(threshold: 10)
        ])
        
        // Tracks aggregate metrics for the entire session
        var summary = AnalysisSummary()
        summary.totalFiles = filePaths.count
        
        // Stores issues per file for the final detailed report
        var fileIssueMap: [String: [Issue]] = [:]
        
        // Iterate through each discovered Swift file
        for filePath in filePaths {
            do {
                // Load source code from disk
                let source = try String(
                    contentsOf: URL(fileURLWithPath: filePath),
                    encoding: .utf8
                )
                
                // Parse the source code into an Abstract Syntax Tree (AST)
                let sourceFile = Parser.parse(source: source)
                
                // Use the visitor to extract class metadata from the AST
                let visitor = ClassVisitor(viewMode: .all)
                visitor.walk(sourceFile)
                
                let fileName = URL(fileURLWithPath: filePath).lastPathComponent
                
                print("\n📄 File: \(fileName)")
                print(String(repeating: "-", count: 40))
                
                // Update aggregate class count
                summary.totalClasses += visitor.classes.count
                
                // Print metrics for each class found in the current file
                for classInfo in visitor.classes {
                    print("📦 Class: \(classInfo.name)")
                    print("   Methods: \(classInfo.methodCount)")
                    print("   Properties: \(classInfo.propertyCount)")
                    print("   Lines: \(classInfo.lineCount)\n")
                }
                
                // Evaluate the extracted class data against the analysis rules
                let issues = engine.analyze(visitor.classes)
                fileIssueMap[fileName] = issues
                
                // Update session summary with newly found issues
                summary.addIssues(issues)
                
                // Print issues immediately for the current file
                for issue in issues {
                    print("   \(issue.severity.rawValue) \(issue.message)")
                }
                
            } catch {
                print("❌ Error reading file: \(filePath)")
                print("   \(error)")
            }
        }
        
        // Generate and print the "Top Files With Issues" leaderboard
        let sortedFiles = fileIssueMap.sorted {
            $0.value.count > $1.value.count
        }
        
        print("\n🚨 Files With Issues (Top 10)")
        print(String(repeating: "-", count: 40))
        
        for (file, issues) in sortedFiles.prefix(10) where !issues.isEmpty {
            print("📄 \(file)")
            
            // Print a subset of issues to avoid excessive console noise
            for issue in issues.prefix(5) {
                if let line = issue.line {
                    print("   \(issue.severity.rawValue) [Line \(line)] \(issue.message)")
                } else {
                    print("   \(issue.severity.rawValue) \(issue.message)")
                }
            }
            
            if issues.count > 5 {
                print("   ...and \(issues.count - 5) more issues")
            }
            print("")
        }

        // Print final aggregate metrics and health status
        print("\n" + String(repeating: "=", count: 40))
        print("📊 Summary")
        print("Files scanned: \(summary.totalFiles)")
        print("Classes analyzed: \(summary.totalClasses)")
        print("Total issues: \(summary.totalIssues)")
        print("⚠️ Warnings: \(summary.warnings)")
        print("ℹ️ Info: \(summary.infos)")
        print("🔴 Critical: \(summary.criticals)")
        
        if summary.totalIssues == 0 {
            print("✅ No issues found. Clean code!")
        }
    }
}
