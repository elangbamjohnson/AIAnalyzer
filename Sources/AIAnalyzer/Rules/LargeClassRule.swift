//
//  LargeClassRule.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation

/// A rule that identifies "God Objects" or oversized classes based on method count.
public struct LargeClassRule: Rule {
    /// The display name for this rule.
    public let name = "LargeClass"
    
    /// The maximum allowed number of methods before a violation is triggered.
    private let threshold: Int
    
    /// Initializes the rule with a custom or default threshold.
    /// - Parameter threshold: The method count limit (defaults to `RuleConstants.largeClassThreshold`).
    public init(threshold: Int = RuleConstants.largeClassThreshold) {
        self.threshold = threshold
    }
    
    /// Flags classes that exceed the defined method count threshold.
    /// - Parameter classInfo: The class metadata to evaluate.
    /// - Returns: A warning `Issue` if the class is too large, otherwise `nil`.
    public func evaluate(_ classInfo: ClassInfo) -> Issue? {
        if classInfo.methodCount > threshold {
            return Issue(
                ruleName: name,
                message: "Class \(classInfo.name) has too many methods (\(classInfo.methodCount)).",
                severity: .warning,
                line: nil
            )
        }
        return nil
    }
}
