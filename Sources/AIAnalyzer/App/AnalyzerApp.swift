import Foundation
import SwiftSyntax
import SwiftParser

@main
struct AnalyzerApp {
    static func main() {
        guard CommandLine.arguments.count > 1 else {
            print("Usage: swift run AIAnalyzer <file.swift>")
            return
        }
        
        let filePath = CommandLine.arguments[1]
        let url = URL(fileURLWithPath: filePath)
        
        do {
            let source = try String(contentsOf: url, encoding: .utf8)
            let sourceFile = Parser.parse(source: source)
            
            let visitor = ClassVisitor(viewMode: .all)
            visitor.walk(sourceFile)
            
            let engine = RuleEngine(rules: [
                LargeClassRule(threshold: 3),
                DataHeavyClassRule(threshold: 1)
            ])
            
            let issues = engine.analyze(visitor.classes)
            
            if issues.isEmpty {
                print("No issues found in \(filePath).")
            } else {
                print("Found \(issues.count) issues in \(filePath):")
                for issue in issues {
                    print("[\(issue.severity.rawValue.uppercased())] \(issue.ruleName): \(issue.message)")
                }
            }
            
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}
