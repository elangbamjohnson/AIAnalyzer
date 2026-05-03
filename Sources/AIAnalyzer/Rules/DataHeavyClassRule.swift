//
//  DataHeavyClassRule.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation

/// A rule that identifies classes primarily used for data storage rather than behavior, based on property count.
public struct DataHeavyClassRule: Rule {
    /// The display name for this rule.
    public let name = "DataHeavyClass"
    
    /// The maximum allowed number of properties before a violation is triggered.
    private let threshold: Int
    
    /// Initializes the rule with a custom or default threshold.
    /// - Parameter threshold: The property count limit (defaults to `RuleConstants.dataHeavyClassThreshold`).
    public init(threshold: Int = RuleConstants.dataHeavyClassThreshold) {
        self.threshold = threshold
    }
    
    /// Flags classes that exceed the defined property count threshold.
    /// - Parameter classInfo: The class metadata to evaluate.
    /// - Returns: An informational `Issue` if the class has too many properties, otherwise `nil`.
    public func evaluate(_ classInfo: ClassInfo) -> Issue? {
        if classInfo.propertyCount > threshold {
            return Issue(
                ruleName: name,
                message: "Type \(classInfo.name) has too many properties (\(classInfo.propertyCount)).",
                severity: .info,
                line: nil
            )
        }
        return nil
    }
}
