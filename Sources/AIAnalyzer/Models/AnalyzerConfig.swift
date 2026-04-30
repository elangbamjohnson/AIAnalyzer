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
        public var largeClass: RuleToggle?
        public var highMethodDensity: RuleToggle?
        public var godObject: RuleToggle?
        public var dataHeavyClass: RuleToggle?
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


