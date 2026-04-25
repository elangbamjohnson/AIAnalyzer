import Foundation

@main
struct AnalyzerApp {
    static func main() {
        guard CommandLine.arguments.count > 1 else {
            print("Usage: swift run AIAnalyzer <file.swift>")
            return
        }
        
        let filePath = CommandLine.arguments[1]
        let url = URL(fileURLWithPath: filePath)
        
        let analyzer = Analyzer(rules: [
            LargeClassRule(threshold: 3),
            DataHeavyClassRule(threshold: 1)
        ])
        
        let reporter: Reporter = ConsoleReporter()
        
        do {
            let issues = try analyzer.analyze(fileURL: url)
            reporter.report(issues: issues, filePath: filePath)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}
