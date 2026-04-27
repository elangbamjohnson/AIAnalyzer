//
//  TooManyMethodsRule.swift
//  AIAnalyzer
//
//  Created by Johnson on 27/04/26.
//


/// A rule that identifies "High Method Density" — many small methods in a single class.
/// This often indicates a violation of the Single Responsibility Principle (SRP).
public struct HighMethodDensityRule: Rule {
    
    /// The display name for this rule.
    public let name = "HighMethodDensity"
    
    /// Default fallback threshold
    private let threshold: Int
    
    public init(threshold: Int = RuleConstants.tooManyMethodThreshold) {
        self.threshold = threshold
    }
    
    public func evaluate(_ classInfo: ClassInfo) -> Issue? {
        
        // ✅ Ignore trivial classes
        if classInfo.lineCount < 20 || classInfo.methodCount == 0 {
            return nil
        }
        
        // ❗ Yield to LargeClassRule for very large files to avoid duplicate reporting
        if classInfo.lineCount > 350 {
            return nil
        }
        
        // ✅ Context-aware method thresholds (stricter than LargeClassRule)
        let methodThreshold: Int
        
        switch classInfo.type {
        case .viewController:
            methodThreshold = 18
        case .viewModel:
            methodThreshold = 12
        case .service:
            methodThreshold = 10
        case .model:
            methodThreshold = 6
        case .unknown:
            methodThreshold = threshold
        }
        
        guard classInfo.methodCount > methodThreshold else {
            return nil
        }
        
        // ✅ Logic check: If methods are large, LargeClassRule is a better fit
        let avgLinesPerMethod = Double(classInfo.lineCount) / Double(classInfo.methodCount)
        if avgLinesPerMethod > 15 {
            return nil
        }
        
        // ✅ Severity scaling
        let severity: Severity = (classInfo.methodCount > methodThreshold * 2) ? .critical : .warning
        
        return Issue(
            ruleName: name,
            message: "Class \(classInfo.name) has high method density (\(classInfo.methodCount) methods). Consider splitting into multiple responsibilities.",
            severity: severity,
            line: nil
        )
    }
}
