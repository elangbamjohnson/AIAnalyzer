//
//  ConsoleReporter.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation

/// An implementation of `Reporter` that outputs analysis results to the standard console.
public struct ConsoleReporter: Reporter {
    /// Initializes a new ConsoleReporter.
    public init() {}
    
    /// Prints the issues found in a file to the console with formatted output.
    /// - Parameters:
    ///   - issues: The list of detected issues.
    ///   - filePath: The path to the file that was analyzed.
    public func report(issues: [Issue], filePath: String) {
        if issues.isEmpty {
            print("No issues found in \(filePath).")
        } else {
            print("Found \(issues.count) issues in \(filePath):")
            for issue in issues {
                print("[\(issue.severity.rawValue.uppercased())] \(issue.ruleName): \(issue.message)")
            }
        }
    }
}
