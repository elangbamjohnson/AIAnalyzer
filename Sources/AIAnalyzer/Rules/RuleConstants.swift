//
//  RuleConstants.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//

import Foundation

/// A collection of default configuration values used by the various analysis rules.
public enum RuleConstants {
    /// Default threshold for the maximum number of methods in a class.
    public static let largeClassThreshold = 10
    
    /// Default threshold for the maximum number of properties in a class.
    public static let dataHeavyClassThreshold = 5
}
