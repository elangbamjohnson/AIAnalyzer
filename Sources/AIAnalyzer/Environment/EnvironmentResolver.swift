//
//  EnvironmentResolver.swift
//  AIAnalyzer
//

import Foundation

/// Loads project-level environment values from `.aianalyzer.env`.
///
/// Walks upward from the scan root so CLI runs from `tools/AIAnalyzer` still pick up the repo-level
/// file. If multiple ancestor directories contain this file, only the **outermost** (closest to the
/// filesystem root) is applied so there is a single source of truth per clone.
enum EnvironmentResolver {
    private static let fileName = ".aianalyzer.env"

    /// Nearest to the scan root first; outermost (repository-level) last.
    private static func envFileChain(fromRootPath rootPath: String) -> [URL] {
        var found: [URL] = []
        var current = URL(fileURLWithPath: rootPath).standardizedFileURL

        while true {
            let candidate = current.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: candidate.path) {
                found.append(candidate)
            }

            let parent = current.deletingLastPathComponent()
            if parent.path == current.path || current.path == "/" {
                break
            }
            current = parent
        }

        return found
    }

    static func apply(fromRootPath rootPath: String, isJsonMode: Bool) {
        let chain = envFileChain(fromRootPath: rootPath)
        guard let outermost = chain.last else {
            return
        }

        if chain.count > 1 {
            let ignored = chain.dropLast().map(\.path).joined(separator: ", ")
            emitWarning(
                "Multiple .aianalyzer.env files found; ignoring nested: \(ignored)",
                isJsonMode: isJsonMode
            )
        }

        guard let contents = try? String(contentsOf: outermost, encoding: .utf8) else {
            emitWarning(
                "Could not read \(outermost.path); continuing with shell environment variables.",
                isJsonMode: isJsonMode
            )
            return
        }

        let entries = parse(contents: contents)
        let keysFromFile = Set(entries.map(\.0))

        for (key, value) in entries {
            setenv(key, value, 1)
        }

        let providerLabel = getenvString("AI_PROVIDER") ?? "unset"
        let providerSource: String
        if keysFromFile.contains("AI_PROVIDER") {
            providerSource = "source: env file"
        } else if providerLabel != "unset" {
            providerSource = "source: inherited from environment (not set in this file)"
        } else {
            providerSource = "source: unset (AIConfiguration defaults to local when absent)"
        }

        emitWarning(
            "Loaded env from \(outermost.path) "
                + "(AI_PROVIDER=\(providerLabel); \(providerSource); envLogFmt=v2)",
            isJsonMode: isJsonMode
        )
    }

    private static func emitWarning(_ message: String, isJsonMode: Bool) {
        let formatted = "warning: [AIAnalyzer] \(message)\n"
        if isJsonMode {
            fputs(formatted, stderr)
        } else {
            print(formatted, terminator: "")
        }
    }

    private static func getenvString(_ name: String) -> String? {
        guard let ptr = getenv(name) else { return nil }
        return String(cString: ptr)
    }

    private static func parse(contents: String) -> [(String, String)] {
        var entries: [(String, String)] = []

        for rawLine in contents.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || line.hasPrefix("#") {
                continue
            }

            guard let separatorIndex = line.firstIndex(of: "=") else {
                continue
            }

            let key = String(line[..<separatorIndex]).trimmingCharacters(in: .whitespaces)
            var value = String(line[line.index(after: separatorIndex)...]).trimmingCharacters(in: .whitespaces)

            // Support optional wrapping quotes for values with spaces.
            if value.count >= 2 {
                let startsWithDoubleQuote = value.hasPrefix("\"")
                let endsWithDoubleQuote = value.hasSuffix("\"")
                let startsWithSingleQuote = value.hasPrefix("'")
                let endsWithSingleQuote = value.hasSuffix("'")
                if (startsWithDoubleQuote && endsWithDoubleQuote) || (startsWithSingleQuote && endsWithSingleQuote) {
                    value.removeFirst()
                    value.removeLast()
                }
            }

            guard !key.isEmpty else {
                continue
            }

            entries.append((key, value))
        }

        return entries
    }
}
