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
        
        // Initialize rule engine and reporter
        let engine = RuleEngine(rules: [
            LargeClassRule(threshold: 10),
            DataHeavyClassRule(threshold: 10),
            HighMethodDensityRule()
        ])
        let reporter: Reporter = ConsoleReporter()
        
        // Tracks aggregate metrics for the entire session
        var summary = AnalysisSummary()
        summary.totalFiles = filePaths.count
        
        // Stores issues per file for the final detailed report
        var fileIssueMap: [String: [Issue]] = [:]
        
        // Iterate through each discovered Swift file
        for filePath in filePaths {
            do {
                let source = try String(contentsOf: URL(fileURLWithPath: filePath), encoding: .utf8)
                let sourceFile = Parser.parse(source: source)
                
                let visitor = ClassVisitor(viewMode: .all)
                visitor.walk(sourceFile)
                
                let fileName = URL(fileURLWithPath: filePath).lastPathComponent
                
                // Evaluate the extracted class data against the analysis rules
                let issues = engine.analyze(visitor.classes)
                fileIssueMap[fileName] = issues
                
                // Update session summary
                summary.totalClasses += visitor.classes.count
                summary.addIssues(issues)
                
                // Use reporter for per-file results
                reporter.report(file: fileName, classes: visitor.classes, issues: issues)
                
            } catch {
                print("❌ Error reading file: \(filePath)\n   \(error)")
            }
        }
        
        // Use reporter for final summary
        reporter.reportSummary(summary, fileIssueMap: fileIssueMap)
    }
}
