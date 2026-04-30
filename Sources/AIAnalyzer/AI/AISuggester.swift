//
//  AISuggester.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 29/04/26.
//

import Foundation

/// `AISuggester` is the central coordinator responsible for bridging the gap between static analysis
/// findings and AI-generated refactoring advice.
///
/// Its primary responsibilities include:
/// - **Prioritization**: Filtering through potentially numerous rule violations to select the most
///   critical issues (Warnings and Critical errors) to send to the AI.
/// - **Context Assembly**: Matching issues to their respective classes and extracting relevant
///   source code snippets to provide the AI with sufficient context.
/// - **Request Management**: Orchestrating the calls to the `AIProvider` while managing user
///   feedback via terminal animations (spinners) during asynchronous operations.
/// - **Safety**: Ensuring that the number of AI requests stays within configured limits to prevent
///   excessive API usage or long execution times.
public struct AISuggester {
    /// The provider used to fulfill AI requests.
    private let provider: AIProvider
    
    /// The maximum number of suggestions to attempt per file.
    private let maxSuggestions: Int
    
    /// The maximum number of lines from the start of the file to provide as context.
    private let snippetLineLimit: Int

    /// Initializes a new suggester.
    /// - Parameters:
    ///   - provider: The AI service provider.
    ///   - maxSuggestions: Maximum number of AI calls.
    ///   - snippetLineLimit: Max lines for code snippets.
    public init(provider: AIProvider, maxSuggestions: Int, snippetLineLimit: Int) {
        self.provider = provider
        self.maxSuggestions = maxSuggestions
        self.snippetLineLimit = snippetLineLimit
    }

    /// Generates refactoring suggestions for a given set of issues and source code.
    /// - Parameters:
    ///   - issues: The list of detected rule violations.
    ///   - classes: The list of classes found in the source.
    ///   - sourceCode: The raw source code of the file.
    /// - Returns: A list of `AISuggestion` objects.
    public func generateSuggestions(
        issues: [Issue],
        classes: [ClassInfo],
        sourceCode: String
    ) -> [AISuggestion] {
        let filtered = issues.filter { $0.severity == .warning || $0.severity == .critical }
        let targetIssues = highestSeverityIssuePerClass(from: filtered, classes: classes)
            .prefix(maxSuggestions)

        let snippet = buildSnippet(sourceCode)
        var results: [AISuggestion] = []

        for issue in targetIssues {
            let classInfo = matchClass(for: issue, from: classes)
            let context = AIRequestContext(issue: issue, classInfo: classInfo, sourceSnippet: snippet)
            let className = classInfo?.name ?? "UnknownClass"
            let requestLabel = "\(issue.ruleName) (\(className))"

            do {
                let suggestion = try withSpinner(message: "⏳ Fetching AI suggestion for \(requestLabel)") {
                    try provider.suggest(for: context)
                }
                results.append(suggestion)
                print("✅ AI suggestion ready for \(requestLabel)")
            } catch {
                print("⚠️ AI suggestion failed for \(issue.ruleName) (\(className)): \(error.localizedDescription)")
                continue
            }
        }

        return results
    }

    /// Filters and sorts issues to ensure we only process the most severe issue per class.
    /// - Parameters:
    ///   - issues: The raw list of filtered issues.
    ///   - classes: The available class information.
    /// - Returns: A prioritized list of issues.
    private func highestSeverityIssuePerClass(from issues: [Issue], classes: [ClassInfo]) -> [Issue] {
        var bestByClass: [String: Issue] = [:]

        for issue in issues {
            let className = matchClass(for: issue, from: classes)?.name ?? "UnknownClass"
            if let current = bestByClass[className] {
                if severityRank(issue.severity) > severityRank(current.severity) {
                    bestByClass[className] = issue
                }
            } else {
                bestByClass[className] = issue
            }
        }

        return Array(bestByClass.values)
            .sorted { severityRank($0.severity) > severityRank($1.severity) }
    }

    /// Extracts a code snippet from the source string based on the line limit.
    /// - Parameter source: The full source code.
    /// - Returns: A truncated code snippet.
    private func buildSnippet(_ source: String) -> String {
        return source
            .split(separator: "\n", omittingEmptySubsequences: false)
            .prefix(snippetLineLimit)
            .joined(separator: "\n")
    }

    /// Attempts to find the specific `ClassInfo` associated with an issue message.
    /// - Parameters:
    ///   - issue: The issue to match.
    ///   - classes: The list of candidate classes.
    /// - Returns: The matching `ClassInfo` or the first available class as a fallback.
    private func matchClass(for issue: Issue, from classes: [ClassInfo]) -> ClassInfo? {
        for classInfo in classes where issue.message.contains(classInfo.name) {
            return classInfo
        }
        return classes.first
    }

    /// Assigns a numerical rank to severity for comparison.
    /// - Parameter severity: The severity level.
    /// - Returns: An integer rank (higher is more severe).
    private func severityRank(_ severity: Severity) -> Int {
        switch severity {
        case .info:
            return 0
        case .warning:
            return 1
        case .critical:
            return 2
        }
    }

    /// Executes an operation while displaying a visual spinner in the terminal.
    /// - Parameters:
    ///   - message: The message to display alongside the spinner.
    ///   - operation: The throwing closure to execute.
    /// - Returns: The result of the operation.
    private func withSpinner<T>(message: String, operation: () throws -> T) throws -> T {
        let frames = ["⏳", "⌛"]
        let stateQueue = DispatchQueue(label: "aianalyzer.spinner.state")
        let spinnerGroup = DispatchGroup()
        var shouldStop = false

        spinnerGroup.enter()
        DispatchQueue.global(qos: .utility).async {
            var index = 0
            while true {
                let stop = stateQueue.sync { shouldStop }
                if stop {
                    break
                }
                let frame = frames[index % frames.count]
                print("\r\(frame) \(message)", terminator: "")
                fflush(stdout)
                index += 1
                Thread.sleep(forTimeInterval: 0.2)
            }
            spinnerGroup.leave()
        }

        do {
            let value = try operation()
            stateQueue.sync { shouldStop = true }
            spinnerGroup.wait()
            print("\r✅ \(message)")
            return value
        } catch {
            stateQueue.sync { shouldStop = true }
            spinnerGroup.wait()
            print("\r❌ \(message)")
            throw error
        }
    }
}
