//
//  AnalysisSummary.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//

import Foundation

/// Accumulates results from the entire analysis session to provide a high-level overview.
struct AnalysisSummary {
    /// Total number of Swift files scanned.
    var totalFiles: Int = 0
    
    /// Total number of classes found and analyzed.
    var totalClasses: Int = 0
    
    /// Aggregate count of all issues found.
    var totalIssues: Int = 0
    
    /// Count of warning-level issues.
    var warnings: Int = 0
    
    /// Count of info-level issues.
    var infos: Int = 0
    
    /// Count of critical-level issues.
    var criticals: Int = 0
    
    /// Updates the summary counters based on a list of new issues.
    /// - Parameter issues: The array of issues to add to the summary.
    mutating func addIssues(_ issues: [Issue]) {
        totalIssues += issues.count
        
        for issue in issues {
            switch issue.severity {
            case .warning:
                warnings += 1
            case .info:
                infos += 1
            case .critical:
                criticals += 1
            }
        }
    }
}
