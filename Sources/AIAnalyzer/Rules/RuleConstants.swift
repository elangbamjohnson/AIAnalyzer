//
//  RuleConstants.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//

import Foundation

/// A collection of default configuration values used by the various analysis rules.
public enum RuleConstants {
    
    // MARK: - Default Thresholds
    public static let largeClassThreshold = 10
    public static let dataHeavyClassThreshold = 5
    public static let tooManyMethodThreshold = 10
    
    // MARK: - Large Class Architectural Limits
    public enum LargeClass {
        public static let vcMethods = 25
        public static let vcLines = 400
        
        public static let vmMethods = 20
        public static let vmLines = 300
        
        public static let serviceMethods = 15
        public static let serviceLines = 250
        
        public static let modelMethods = 10
        public static let modelLines = 150
        
        public static let defaultLines = 300
    }
    
    // MARK: - God Object Architectural Limits
    public enum GodObject {
        public static let vcMethods = 40
        public static let vcProperties = 20
        public static let vcLines = 600
        
        public static let vmMethods = 30
        public static let vmProperties = 15
        public static let vmLines = 450
        
        public static let serviceMethods = 25
        public static let serviceProperties = 12
        public static let serviceLines = 350
        
        public static let modelMethods = 15
        public static let modelProperties = 20
        public static let modelLines = 250
        
        public static let defaultMethods = 30
        public static let defaultProperties = 15
        public static let defaultLines = 400
    }
}
