import Foundation

public struct ConsoleReporter: Reporter {
    public init() {}
    
    public func report(issues: [Issue], filePath: String) {
        if issues.isEmpty {
            print("No issues found in \(filePath).")
        } else {
            print("Found \(issues.count) issues in \(filePath):")
            for issue in issues {
                print("[\(issue.severity.rawValue.uppercased())] \(issue.ruleName): \(issue.message)")
            }
        }
    }
}
