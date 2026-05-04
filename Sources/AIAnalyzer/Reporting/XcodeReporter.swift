import Foundation

/// An implementation of `Reporter` that outputs analysis results in a format recognized by Xcode.
/// Format: <path>:<line>: <warning|error|note>: <message>
public struct XcodeReporter: Reporter {
    private let rootPath: String

    public init(rootPath: String) {
        self.rootPath = rootPath
    }

    public func report(file: String, classes: [ClassInfo], issues: [Issue]) {
        // Find the full path for the file within the rootPath
        let fileURL = URL(fileURLWithPath: rootPath).appendingPathComponent(file)
        let fullPath = fileURL.path

        for issue in issues {
            let line = issue.line ?? 1
            let xcodeSeverity: String
            switch issue.severity {
            case .critical:
                xcodeSeverity = "error"
            case .warning:
                xcodeSeverity = "warning"
            case .info:
                xcodeSeverity = "note"
            }

            // Print in Xcode-compatible format
            print("\(fullPath):\(line): \(xcodeSeverity): [AIAnalyzer] \(issue.message)")
        }
    }

    public func reportSummary(_ summary: AnalysisSummary, fileIssueMap: [String: [Issue]]) {
        // Xcode reporter typically doesn't need a summary, as it prefers inline markers.
        // However, we can emit a note for the final count.
        print("note: [AIAnalyzer] Analysis complete. Found \(summary.issueCounts.total) issues in \(summary.totalFiles) files.")
    }
}
