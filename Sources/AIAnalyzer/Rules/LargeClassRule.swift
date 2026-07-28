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
    private let vcMethods: Int
    private let vcLines: Int
    private let vmMethods: Int
    private let vmLines: Int
    private let serviceMethods: Int
    private let serviceLines: Int
    private let modelMethods: Int
    private let modelLines: Int
    
    /// Initializes the rule with custom or default thresholds.
    public init(
        threshold: Int = RuleConstants.largeClassThreshold,
        vcMethods: Int = RuleConstants.LargeClass.vcMethods,
        vcLines: Int = RuleConstants.LargeClass.vcLines,
        vmMethods: Int = RuleConstants.LargeClass.vmMethods,
        vmLines: Int = RuleConstants.LargeClass.vmLines,
        serviceMethods: Int = RuleConstants.LargeClass.serviceMethods,
        serviceLines: Int = RuleConstants.LargeClass.serviceLines,
        modelMethods: Int = RuleConstants.LargeClass.modelMethods,
        modelLines: Int = RuleConstants.LargeClass.modelLines
    ) {
        self.threshold = threshold
        self.vcMethods = vcMethods
        self.vcLines = vcLines
        self.vmMethods = vmMethods
        self.vmLines = vmLines
        self.serviceMethods = serviceMethods
        self.serviceLines = serviceLines
        self.modelMethods = modelMethods
        self.modelLines = modelLines
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
            methodThreshold = vcMethods
            lineThreshold = vcLines
        case .viewModel:
            methodThreshold = vmMethods
            lineThreshold = vmLines
        case .service:
            methodThreshold = serviceMethods
            lineThreshold = serviceLines
        case .model:
            methodThreshold = modelMethods
            lineThreshold = modelLines
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
