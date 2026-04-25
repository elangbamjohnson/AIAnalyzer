//
//  DataHeavyClassRule.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation

public struct DataHeavyClassRule: Rule {
    public let name = "DataHeavyClass"
    private let threshold: Int
    
    public init(threshold: Int = 5) {
        self.threshold = threshold
    }
    
    public func evaluate(_ classInfo: ClassInfo) -> Issue? {
        if classInfo.propertyCount > threshold {
            return Issue(
                ruleName: name,
                message: "Class \(classInfo.name) has too many properties (\(classInfo.propertyCount)).",
                severity: .info,
                line: nil
            )
        }
        return nil
    }
}
