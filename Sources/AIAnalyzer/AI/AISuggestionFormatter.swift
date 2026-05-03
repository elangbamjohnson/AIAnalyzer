//
//  AISuggestionFormatter.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 30/04/26.
//

import Foundation

/// `AISuggestionFormatter` is a presentation utility responsible for turning raw AI-generated text
/// into a structured, aesthetically pleasing terminal report.
///
/// Its core responsibilities include:
/// - **Sectional Parsing**: Deconstructing the AI's response into logical blocks like "Root Cause,"
///   "Refactor Steps," and "Quick Wins" by identifying common header keywords.
/// - **Text Sanitization**: Cleaning up common LLM artifacts like excessive markdown bolding (`**`)
///   or backticks (`` ` ``) that may not render correctly in all terminal environments.
/// - **Verbose Management**: Toggling between a compact summary view and a full detailed report
///   based on user environment settings.
/// - **Fallback Logic**: Providing a sensible "compact" display if the AI returns unstructured text
///   that doesn't match expected headers.
enum AISuggestionFormatter {
    /// Formats a suggestion into a multi-line string with headers and sections.
    /// - Parameters:
    ///   - suggestion: The suggestion to format.
    ///   - verbose: Whether to include the raw AI output and more lines for generic suggestions.
    /// - Returns: A formatted string suitable for the terminal.
    static func format(_ suggestion: AISuggestion, verbose: Bool) -> String {
        let parsed = parseSections(from: suggestion.content.suggestedRefactor)
        var lines: [String] = []

        lines.append("\(suggestion.metadata.severity.rawValue) \(severityLabel(suggestion.metadata.severity)) [\(suggestion.metadata.ruleName)]")
        lines.append("Type       : \(suggestion.metadata.typeName)")
        lines.append("Model      : \(suggestion.content.modelSource)")
        lines.append("Diagnosis  : \(clean(suggestion.content.diagnosis))")
        lines.append("")

        if !parsed.rootCause.isEmpty {
            lines.append("Root Cause")
            lines.append(contentsOf: parsed.rootCause.map { "- \($0)" })
            lines.append("")
        }

        if !parsed.refactorSteps.isEmpty {
            lines.append("Refactor Steps")
            lines.append(contentsOf: parsed.refactorSteps.map { "- \($0)" })
            lines.append("")
        }

        if !parsed.quickWin.isEmpty {
            lines.append("Quick Win")
            lines.append(contentsOf: parsed.quickWin.map { "- \($0)" })
            lines.append("")
        }

        if parsed.isEmpty {
            let compact = compactLines(suggestion.content.suggestedRefactor, maxLines: verbose ? 20 : 8)
            lines.append("Suggestion")
            lines.append(contentsOf: compact.map { "- \($0)" })
            if !verbose && compact.count >= 8 {
                lines.append("- ... set AI_VERBOSE=true for full AI text")
            }
            lines.append("")
        }

        if verbose {
            lines.append("Raw AI Output")
            lines.append(clean(suggestion.content.suggestedRefactor))
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    /// Converts a severity enum into a displayable string.
    private static func severityLabel(_ severity: Severity) -> String {
        switch severity {
        case .critical: return "Critical"
        case .warning: return "Warning"
        case .info: return "Info"
        }
    }

    /// Removes markdown symbols and extra whitespace from a string.
    private static func clean(_ text: String) -> String {
        text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "`", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Splits text into lines and removes empty ones, capped by `maxLines`.
    private static func compactLines(_ text: String, maxLines: Int) -> [String] {
        text
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { clean(String($0)) }
            .filter { !$0.isEmpty }
            .prefix(maxLines)
            .map { $0 }
    }

    /// Parses the structured AI output into specific semantic sections.
    /// - Parameter text: The raw text from the AI.
    /// - Returns: A tuple containing the extracted sections and a boolean indicating if any structured section was found.
    private static func parseSections(from text: String) -> (rootCause: [String], refactorSteps: [String], quickWin: [String], isEmpty: Bool) {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map { clean(String($0)) }
        enum Section { case none, rootCause, refactorSteps, quickWin }
        var section: Section = .none
        var rootCause: [String] = []
        var refactorSteps: [String] = []
        var quickWin: [String] = []

        for line in lines {
            let lower = line.lowercased()
            if lower.contains("root cause") {
                section = .rootCause
                continue
            }
            if lower.contains("refactor steps") {
                section = .refactorSteps
                continue
            }
            if lower.contains("quick win") {
                section = .quickWin
                continue
            }
            if line.isEmpty {
                continue
            }

            let normalized = line
                .replacingOccurrences(of: "- ", with: "")
                .replacingOccurrences(of: "* ", with: "")
                .replacingOccurrences(of: "• ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            switch section {
            case .rootCause:
                rootCause.append(normalized)
            case .refactorSteps:
                refactorSteps.append(normalized)
            case .quickWin:
                quickWin.append(normalized)
            case .none:
                continue
            }
        }

        let isEmpty = rootCause.isEmpty && refactorSteps.isEmpty && quickWin.isEmpty
        return (rootCause, refactorSteps, quickWin, isEmpty)
    }
}
