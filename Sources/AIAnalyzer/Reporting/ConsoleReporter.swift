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

    public func report(file: String, classes: [ClassInfo], issues: [Issue]) {
        print("\n📄 File: \(file)")
        print(String(repeating: "-", count: 40))

        for classInfo in classes {
            print("📦 Type: \(classInfo.name) [\(classInfo.type)]")
            print("   Inits: \(classInfo.initializerCount) | Accessors: \(classInfo.accessorCount) | Subscripts: \(classInfo.subscriptCount)")
            print("   Methods: \(classInfo.methodCount) | Properties: \(classInfo.propertyCount) | Lines: \(classInfo.lineCount)")

            if !classInfo.memberInfos.isEmpty {
                print("   Members Map:")
                for member in classInfo.memberInfos {
                    print("      - \(member.name) (Lines \(member.startLine)-\(member.endLine))")
                }
            }
        }


        if !issues.isEmpty {
            print("")
            for issue in issues {
                print("   \(issue.severity.rawValue) \(issue.message)")
            }
        }
    }

    public func reportSummary(_ summary: AnalysisSummary, fileIssueMap: [String: [Issue]]) {
        // Generate and print the "Top Files With Issues" leaderboard
        let sortedFiles = fileIssueMap.sorted {
            $0.value.count > $1.value.count
        }

        print("\n🚨 Files With Issues (Top 10)")
        print(String(repeating: "-", count: 40))

        for (file, issues) in sortedFiles.prefix(10) where !issues.isEmpty {
            print("📄 \(file)")
            for issue in issues.prefix(5) {
                let lineInfo = issue.line != nil ? "[Line \(issue.line!)] " : ""
                print("   \(issue.severity.rawValue) \(lineInfo)\(issue.message)")
            }
            if issues.count > 5 {
                print("   ...and \(issues.count - 5) more issues")
            }
            print("")
        }

        // Print final aggregate metrics
        print("\n" + String(repeating: "=", count: 40))
        print("📊 Summary")
        print("Files scanned: \(summary.totalFiles)")
        print("Types analyzed: \(summary.totalClasses)")
        print("Total issues: \(summary.issueCounts.total)")
        print("⚠️ Warnings: \(summary.issueCounts.warnings) | ℹ️ Info: \(summary.issueCounts.infos) | 🔴 Critical: \(summary.issueCounts.criticals)")

        if summary.issueCounts.total == 0 {
            print("✅ No issues found. Clean code!")
        }
        print(String(repeating: "=", count: 40) + "\n")
    }
}
