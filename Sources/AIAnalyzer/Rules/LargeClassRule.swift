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
    
    /// Flags classes that exceed context-aware thresholds for methods or lines.
    /// - Parameter classInfo: The class metadata to evaluate.
    /// - Returns: An `Issue` if the class is too large, otherwise `nil`.
    public func evaluate(_ classInfo: ClassInfo) -> Issue? {
        // Context-aware thresholds
        let methodThreshold: Int
        let lineThreshold: Int
        
        switch classInfo.type {
        case .viewController:
            methodThreshold = RuleConstants.LargeClass.vcMethods
            lineThreshold = RuleConstants.LargeClass.vcLines
        case .viewModel:
            methodThreshold = RuleConstants.LargeClass.vmMethods
            lineThreshold = RuleConstants.LargeClass.vmLines
        case .service:
            methodThreshold = RuleConstants.LargeClass.serviceMethods
            lineThreshold = RuleConstants.LargeClass.serviceLines
        case .model:
            methodThreshold = RuleConstants.LargeClass.modelMethods
            lineThreshold = RuleConstants.LargeClass.modelLines
        case .unknown:
            methodThreshold = threshold
            lineThreshold = RuleConstants.LargeClass.defaultLines
        }
        
        let exceedsMethods = classInfo.methodCount > methodThreshold
        let exceedsLines = classInfo.lineCount > lineThreshold
        
        guard exceedsMethods || exceedsLines else {
            return nil
        }
        
        // Determine severity
        let severity: Severity = (classInfo.methodCount > methodThreshold * 2 || classInfo.lineCount > lineThreshold * 2) ? .critical : .warning
        
        // Build detailed message
        var reasons: [String] = []
        if exceedsMethods {
            reasons.append("\(classInfo.methodCount) methods (limit: \(methodThreshold))")
        }
        if exceedsLines {
            reasons.append("\(classInfo.lineCount) lines (limit: \(lineThreshold))")
        }
        
        return Issue(
            ruleName: name,
            message: "Type \(classInfo.name) is too large: \(reasons.joined(separator: ", "))",
            severity: severity,
            line: nil
        )
    }
}
