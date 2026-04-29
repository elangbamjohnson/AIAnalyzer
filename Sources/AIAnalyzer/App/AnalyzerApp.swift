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

    static func main() {
        
        // 1. Validate input
        guard CommandLine.arguments.count > 1 else {
            print("Usage: swift run AIAnalyzer <file.swift | folder>")
            exit(1)
        }

        let inputPath = CommandLine.arguments[1]
        let fullPath = URL(fileURLWithPath: inputPath).standardized.path
        
        var isDirectory: ObjCBool = false
        
        guard FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory) else {
            print("❌ Path does not exist")
            exit(1)
        }

        if let validationError = InputPathValidator.singleFileExtensionError(
            for: fullPath,
            isDirectory: isDirectory.boolValue
        ) {
            print(validationError)
            exit(1)
        }
        
        // 2. Determine root for config
        let rootPath = isDirectory.boolValue
            ? fullPath
            : URL(fileURLWithPath: fullPath).deletingLastPathComponent().path
        
        let config = ConfigLoader.load(from: rootPath)
        
        // 3. Scan files
        let filePaths: [String]
        
        if isDirectory.boolValue {
            print("📂 Scanning folder: \(fullPath)")
            filePaths = FileScanner.getSwiftFiles(in: fullPath, ignoring: config.ignoreDirectories)
        } else {
            filePaths = [fullPath]
        }
        
        guard !filePaths.isEmpty else {
            print("⚠️ No Swift files found.")
            exit(0)
        }
        
        print("📊 Found \(filePaths.count) Swift files\n")
        
        // 4. Build rules from config
        var rules: [Rule] = []
        
        if config.rules?.largeClass?.enabled == true {
            let threshold = config.rules?.largeClass?.threshold ?? RuleConstants.largeClassThreshold
            rules.append(LargeClassRule(threshold: threshold))
        }
        
        if config.rules?.highMethodDensity?.enabled == true {
            let threshold = config.rules?.highMethodDensity?.threshold ?? RuleConstants.tooManyMethodThreshold
            rules.append(HighMethodDensityRule(threshold: threshold))
        }
        
        if config.rules?.godObject?.enabled == true {
            rules.append(GodObjectRule())
        }

        if config.rules?.dataHeavyClass?.enabled == true {
            let threshold = config.rules?.dataHeavyClass?.threshold ?? RuleConstants.dataHeavyClassThreshold
            rules.append(DataHeavyClassRule(threshold: threshold))
        }
        
        let engine = RuleEngine(rules: rules)
        let reporter: Reporter = ConsoleReporter()
        
        var summary = AnalysisSummary()
        summary.totalFiles = filePaths.count
        
        var fileIssueMap: [String: [Issue]] = [:]
        
        // 5. Process files
        for filePath in filePaths {
            do {
                let source = try String(contentsOf: URL(fileURLWithPath: filePath), encoding: .utf8)
                let sourceFile = Parser.parse(source: source)
                
                let visitor = ClassVisitor(viewMode: .all)
                visitor.walk(sourceFile)
                
                let issues = engine.analyze(visitor.classes)
                fileIssueMap[filePath] = issues
                
                summary.totalClasses += visitor.classes.count
                summary.addIssues(issues)
                
                reporter.report(file: filePath, classes: visitor.classes, issues: issues)
                
            } catch {
                print("❌ Error reading file: \(filePath)\n   \(error)")
            }
        }
        
        // 6. Final summary
        reporter.reportSummary(summary, fileIssueMap: fileIssueMap)
    }
}
