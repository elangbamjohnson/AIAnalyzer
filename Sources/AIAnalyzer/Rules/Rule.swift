//
//  Rule.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation

/// A protocol that defines a contract for code analysis rules.
/// Custom rules must implement this protocol to be used by the RuleEngine.
public protocol Rule {
    /// The unique identifier or name for the rule.
    var name: String { get }
    
    /// Evaluates a class against the rule's criteria.
    /// - Parameter classInfo: Structural data about the class being analyzed.
    /// - Returns: An `Issue` if a violation is detected, otherwise `nil`.
    func evaluate(_ classInfo: ClassInfo) -> Issue?
}
