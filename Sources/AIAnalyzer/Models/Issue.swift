//
//  Issue.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation

/// Represents a code smell or architectural issue found by the analyzer.
public struct Issue: Codable {
    /// The name of the rule that triggered this issue.
    public let ruleName: String
    
    /// A descriptive message explaining the issue.
    public let message: String
    
    /// The importance level of the issue (info, warning, or error).
    public let severity: Severity
    
    /// The line number where the issue was detected, if available.
    public let line: Int?
    
    /// Initializes a new Issue instance.
    /// - Parameters:
    ///   - ruleName: Name of the originating rule.
    ///   - message: Explanation of the issue.
    ///   - severity: Severity level.
    ///   - line: Optional line number.
    public init(ruleName: String, message: String, severity: Severity, line: Int? = nil) {
        self.ruleName = ruleName
        self.message = message
        self.severity = severity
        self.line = line
    }
}
