//
//  AnalyzerConfig.swift
//  AIAnalyzer
//
//  Created by Johnson on 28/04/26.
//

public struct AnalyzerConfig: Codable {
    
    public var ignoreDirectories: [String]?
    public var rules: RuleConfig?
    
    public struct RuleConfig: Codable {
        public var largeClass: LargeClassRuleConfig?
        public var highMethodDensity: RuleToggle?
        public var godObject: RuleToggle?
        public var dataHeavyClass: RuleToggle?
        /// MVVM architectural rule: flags ViewModel types that import UIKit.
        public var viewModelUIKit: RuleToggle?
        /// Layering rule: flags Model/Service types whose file imports UIKit.
        public var modelServiceUIKit: RuleToggle?
    }
    
    public struct LargeClassRuleConfig: Codable {
        public var enabled: Bool?
        public var threshold: Int?
        public var vcMethods: Int?
        public var vcLines: Int?
        public var vmMethods: Int?
        public var vmLines: Int?
        public var serviceMethods: Int?
        public var serviceLines: Int?
        public var modelMethods: Int?
        public var modelLines: Int?

        public init(
            enabled: Bool? = nil,
            threshold: Int? = nil,
            vcMethods: Int? = nil,
            vcLines: Int? = nil,
            vmMethods: Int? = nil,
            vmLines: Int? = nil,
            serviceMethods: Int? = nil,
            serviceLines: Int? = nil,
            modelMethods: Int? = nil,
            modelLines: Int? = nil
        ) {
            self.enabled = enabled
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
    }
    
    public struct RuleToggle: Codable {
        public var enabled: Bool?
        public var threshold: Int?
        
        public init(enabled: Bool? = nil, threshold: Int? = nil) {
            self.enabled = enabled
            self.threshold = threshold
        }
    }
}


