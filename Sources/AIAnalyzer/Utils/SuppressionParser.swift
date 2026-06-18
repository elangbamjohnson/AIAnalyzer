//
//  SuppressionParser.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 18/06/26.
//

import Foundation

/// Parses source comments that intentionally suppress analyzer findings.
///
/// Supported file-level forms:
/// - `// aianalyzer:disable LargeClass`
/// - `// aianalyzer:disable LargeClass, GodObject`
/// - `// aianalyzer:disable all`
struct SuppressionParser {
    private static let directive = "aianalyzer:disable"

    static func suppressedRuleNames(in source: String) -> Set<String> {
        var suppressed: Set<String> = []

        for line in source.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard trimmedLine.hasPrefix("//") else {
                continue
            }

            let comment = trimmedLine.dropFirst(2)
            guard let directiveRange = comment.range(of: directive) else {
                continue
            }

            let rawRules = comment[directiveRange.upperBound...]
            for ruleName in parseRuleNames(from: String(rawRules)) {
                suppressed.insert(ruleName)
            }
        }

        return suppressed
    }

    static func filter(_ issues: [Issue], suppressedRuleNames: Set<String>) -> [Issue] {
        guard !suppressedRuleNames.isEmpty else {
            return issues
        }

        let normalized = Set(suppressedRuleNames.map { $0.lowercased() })
        if normalized.contains("all") {
            return []
        }

        return issues.filter { !normalized.contains($0.ruleName.lowercased()) }
    }

    private static func parseRuleNames(from rawRules: String) -> [String] {
        rawRules
            .split { character in
                character == "," || character == " " || character == "\t"
            }
            .map { token in
                token.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
    }
}
