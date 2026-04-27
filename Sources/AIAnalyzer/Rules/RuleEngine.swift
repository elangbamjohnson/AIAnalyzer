//
//  RuleEngine.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation

/// Coordinates the execution of multiple rules against extracted class information.
public class RuleEngine {
    /// The collection of rules to be applied during analysis.
    private let rules: [Rule]
    
    /// Initializes the engine with a set of rules.
    /// - Parameter rules: An array of objects conforming to the `Rule` protocol.
    public init(rules: [Rule]) {
        self.rules = rules
    }
    
    /// Analyzes a list of classes by running every registered rule against each class.
    /// - Parameter classes: The structural information for classes to analyze.
    /// - Returns: An aggregate array of all detected issues.
    public func analyze(_ classes: [ClassInfo]) -> [Issue] {
        var issues: [Issue] = []
        for classInfo in classes {
            for rule in rules {
                if let issue = rule.evaluate(classInfo) {
                    issues.append(issue)
                }
            }
        }
        return issues
    }
}
