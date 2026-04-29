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
    private let godObjectRuleName = "GodObject"
    private let redundantWithGodObject: Set<String> = [
        "LargeClass",
        "DataHeavyClass"
    ]
    
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
            var classIssues: [Issue] = []
            for rule in rules {
                if let issue = rule.evaluate(classInfo) {
                    classIssues.append(issue)
                }
            }
            issues.append(contentsOf: filterOverlappingIssues(classIssues))
        }
        return issues
    }

    private func filterOverlappingIssues(_ issues: [Issue]) -> [Issue] {
        let hasGodObject = issues.contains { $0.ruleName == godObjectRuleName }
        guard hasGodObject else {
            return issues
        }

        return issues.filter { !redundantWithGodObject.contains($0.ruleName) }
    }
}
