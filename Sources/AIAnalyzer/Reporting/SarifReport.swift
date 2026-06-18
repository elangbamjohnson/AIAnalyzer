//
//  SarifReport.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 18/06/26.
//

import Foundation

enum SarifReport {
    static func make(from issues: [IssueReport]) -> Log {
        let rules = issues
            .map(\.rule)
            .uniqued()
            .map { ruleName in
                ReportingDescriptor(
                    id: ruleName,
                    name: ruleName,
                    shortDescription: Message(text: "\(ruleName) finding")
                )
            }

        let results = issues.map { issue in
            Result(
                ruleId: issue.rule,
                level: level(for: issue.severity),
                message: Message(text: issue.message),
                locations: [
                    Location(
                        physicalLocation: PhysicalLocation(
                            artifactLocation: ArtifactLocation(uri: issue.file),
                            region: Region(startLine: issue.line ?? 1)
                        )
                    )
                ]
            )
        }

        return Log(
            version: "2.1.0",
            schema: "https://json.schemastore.org/sarif-2.1.0.json",
            runs: [
                Run(
                    tool: Tool(
                        driver: Driver(
                            name: "AIAnalyzer",
                            informationUri: "https://github.com/elangbamjohnson/AIAnalyzer",
                            rules: rules
                        )
                    ),
                    results: results
                )
            ]
        )
    }

    private static func level(for severity: String) -> String {
        switch severity {
        case Severity.critical.rawValue:
            return "error"
        case Severity.warning.rawValue:
            return "warning"
        default:
            return "note"
        }
    }

    struct Log: Codable {
        let version: String
        let schema: String
        let runs: [Run]

        enum CodingKeys: String, CodingKey {
            case version
            case schema = "$schema"
            case runs
        }
    }

    struct Run: Codable {
        let tool: Tool
        let results: [Result]
    }

    struct Tool: Codable {
        let driver: Driver
    }

    struct Driver: Codable {
        let name: String
        let informationUri: String
        let rules: [ReportingDescriptor]
    }

    struct ReportingDescriptor: Codable {
        let id: String
        let name: String
        let shortDescription: Message
    }

    struct Result: Codable {
        let ruleId: String
        let level: String
        let message: Message
        let locations: [Location]
    }

    struct Message: Codable {
        let text: String
    }

    struct Location: Codable {
        let physicalLocation: PhysicalLocation
    }

    struct PhysicalLocation: Codable {
        let artifactLocation: ArtifactLocation
        let region: Region
    }

    struct ArtifactLocation: Codable {
        let uri: String
    }

    struct Region: Codable {
        let startLine: Int
    }
}

private extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var seen: Set<Element> = []
        var result: [Element] = []

        for element in self where seen.insert(element).inserted {
            result.append(element)
        }

        return result
    }
}
