//
//  SourceRedactor.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 18/06/26.
//

import Foundation

/// Redacts obvious secrets before source snippets are sent to AI providers.
enum SourceRedactor {
    private static let redactedToken = "[REDACTED]"

    static func redact(_ source: String) -> String {
        var result = source

        result = replaceMatches(
            in: result,
            pattern: #"(?i)\b(api[_-]?key|token|secret|password|client[_-]?secret)\b\s*(?::\s*[^=\n]+)?=\s*["'][^"']+["']"#,
            transform: { match in
                guard let separatorIndex = match.firstIndex(where: { $0 == ":" || $0 == "=" }) else {
                    return match
                }

                let prefix = match[..<match.index(after: separatorIndex)]
                if match[separatorIndex] == ":",
                   let equalsIndex = match.firstIndex(of: "=") {
                    let typedPrefix = match[..<match.index(after: equalsIndex)]
                    return "\(typedPrefix) \"\(redactedToken)\""
                }

                return "\(prefix) \"\(redactedToken)\""
            }
        )

        result = replaceMatches(
            in: result,
            pattern: #"(?i)"?\b(api[_-]?key|token|secret|password|client[_-]?secret)\b"?\s*:\s*["'][^"']+["']"#,
            transform: { match in
                guard let separatorIndex = match.firstIndex(of: ":") else {
                    return match
                }

                let prefix = match[..<match.index(after: separatorIndex)]
                return "\(prefix) \"\(redactedToken)\""
            }
        )

        result = replaceMatches(
            in: result,
            pattern: #"(?i)\b(bearer)\s+[A-Za-z0-9._~+/=-]{12,}"#,
            transform: { match in
                let prefix = match.prefix { !$0.isWhitespace }
                return "\(prefix) \(redactedToken)"
            }
        )

        return result
    }

    private static func replaceMatches(
        in source: String,
        pattern: String,
        transform: (String) -> String
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return source
        }

        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        let matches = regex.matches(in: source, range: range).reversed()
        var result = source

        for match in matches {
            guard let range = Range(match.range, in: result) else {
                continue
            }

            let replacement = transform(String(result[range]))
            result.replaceSubrange(range, with: replacement)
        }

        return result
    }
}
