//
//  ClassInfo.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation

/// Represents structural information about a Swift class extracted during analysis.
public struct ClassInfo {
    /// The name of the class.
    public let name: String
    
    /// The number of methods defined within the class.
    public let methodCount: Int
    
    /// The number of properties (variables) defined within the class.
    public let propertyCount: Int
    
    /// The total number of lines in the class declaration block.
    public let lineCount: Int
    
    /// Initializes a new ClassInfo instance with the provided metrics.
    /// - Parameters:
    ///   - name: The class name.
    ///   - methodCount: Count of methods.
    ///   - propertyCount: Count of properties.
    ///   - lineCount: Count of lines.
    public init(name: String, methodCount: Int, propertyCount: Int, lineCount: Int) {
        self.name = name
        self.methodCount = methodCount
        self.propertyCount = propertyCount
        self.lineCount = lineCount
    }
}
