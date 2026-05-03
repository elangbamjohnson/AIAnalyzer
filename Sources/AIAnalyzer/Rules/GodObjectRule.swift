//
//  GodObjectRule.swift
//  AIAnalyzer
//
//  Created by Johnson on 27/04/26.
//

import Foundation

/// A high-level rule that identifies "True God Objects" — classes that are 
/// simultaneously too large, too complex, and too data-heavy.
/// This rule requires multiple violations to trigger, reducing noise.
public struct GodObjectRule: Rule {
    
    public let name = "GodObject"
    
    public init() {}
    
    public func evaluate(_ classInfo: ClassInfo) -> Issue? {
        
        // Context-aware "God Tier" thresholds
        let methodLimit: Int
        let propertyLimit: Int
        let lineLimit: Int
        
        switch classInfo.type {
        case .viewController:
            methodLimit = RuleConstants.GodObject.vcMethods
            propertyLimit = RuleConstants.GodObject.vcProperties
            lineLimit = RuleConstants.GodObject.vcLines
        case .viewModel:
            methodLimit = RuleConstants.GodObject.vmMethods
            propertyLimit = RuleConstants.GodObject.vmProperties
            lineLimit = RuleConstants.GodObject.vmLines
        case .service:
            methodLimit = RuleConstants.GodObject.serviceMethods
            propertyLimit = RuleConstants.GodObject.serviceProperties
            lineLimit = RuleConstants.GodObject.serviceLines
        case .model:
            methodLimit = RuleConstants.GodObject.modelMethods
            propertyLimit = RuleConstants.GodObject.modelProperties
            lineLimit = RuleConstants.GodObject.modelLines
        case .unknown:
            methodLimit = RuleConstants.GodObject.defaultMethods
            propertyLimit = RuleConstants.GodObject.defaultProperties
            lineLimit = RuleConstants.GodObject.defaultLines
        }
        
        let exceedsMethods = classInfo.methodCount > methodLimit
        let exceedsProperties = classInfo.propertyCount > propertyLimit
        let exceedsLines = classInfo.lineCount > lineLimit
        
        // ✅ A God Object is defined by multiple simultaneous violations
        let signals = [exceedsMethods, exceedsProperties, exceedsLines].filter { $0 }.count
        
        // Only trigger if at least 2 major signals are present
        guard signals >= 2 else {
            return nil
        }
        
        // ✅ Severity is always critical for God Objects
        let severity: Severity = .critical
        
        var reasons: [String] = []
        if exceedsMethods { reasons.append("\(classInfo.methodCount) methods") }
        if exceedsProperties { reasons.append("\(classInfo.propertyCount) properties") }
        if exceedsLines { reasons.append("\(classInfo.lineCount) lines") }
        
        return Issue(
            ruleName: name,
            message: "Type \(classInfo.name) is a God Object (Major SRP violation). It exceeds multiple limits: \(reasons.joined(separator: ", ")).",
            severity: severity,
            line: nil
        )
    }
}
