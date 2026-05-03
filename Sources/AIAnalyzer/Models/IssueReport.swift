//
//  IssueReport.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 03/05/26.
//

import Foundation

/// A machine-readable structure representing a single detected issue,
/// suitable for CI/CD integrations and external tools.
public struct IssueReport: Codable {
    /// The name of the rule that was violated.
    public let rule: String
    /// The severity level (info, warning, critical).
    public let severity: String
    /// The human-readable message describing the violation.
    public let message: String
    /// The file path where the issue was found.
    public let file: String
    /// The 1-based line number if available.
    public let line: Int?
    /// The name of the class or struct (Type) containing the issue.
    public let typeName: String

    public init(rule: String, severity: String, message: String, file: String, line: Int?, typeName: String) {
        self.rule = rule
        self.severity = severity
        self.message = message
        self.file = file
        self.line = line
        self.typeName = typeName
    }
}
