//
//  AnalysisSummary.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//

import Foundation

/// Accumulates results from the entire analysis session to provide a high-level overview.
public struct AnalysisSummary {
    /// Represents the counts of different types of issues.
    public struct IssueCounts {
        /// Aggregate count of all issues found.
        public var total: Int = 0
        /// Count of warning-level issues.
        public var warnings: Int = 0
        /// Count of info-level issues.
        public var infos: Int = 0
        /// Count of critical-level issues.
        public var criticals: Int = 0
    }

    /// Total number of Swift files scanned.
    public var totalFiles: Int = 0
    
    /// Total number of classes found and analyzed.
    public var totalClasses: Int = 0
    
    /// Counts of various issue severities.
    public var issueCounts: IssueCounts = IssueCounts()
    
    public init() {}
    
    /// Updates the summary counters based on a list of new issues.
    /// - Parameter issues: The array of issues to add to the summary.
    public mutating func addIssues(_ issues: [Issue]) {
        issueCounts.total += issues.count
        
        for issue in issues {
            switch issue.severity {
            case .warning:
                issueCounts.warnings += 1
            case .info:
                issueCounts.infos += 1
            case .critical:
                issueCounts.criticals += 1
            }
        }
    }
}
