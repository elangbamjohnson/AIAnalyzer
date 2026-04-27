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
    func report(file: String, classes: [ClassInfo], issues: [Issue])
    
    /// Generates the final aggregate summary for the entire analysis session.
    func reportSummary(_ summary: AnalysisSummary, fileIssueMap: [String: [Issue]])
}
