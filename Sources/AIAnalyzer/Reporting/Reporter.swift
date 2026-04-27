//
//  Reporter.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation

/// A protocol that defines how analysis results should be presented to the user.
public protocol Reporter {
    /// Generates a report for the issues found in a specific file.
    /// - Parameters:
    ///   - issues: The list of detected issues.
    ///   - filePath: The path to the file that was analyzed.
    func report(issues: [Issue], filePath: String)
}
