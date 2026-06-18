//
//  SarifReportTests.swift
//  AIAnalyzerTests
//
//  Created by Johnson Elangbam on 18/06/26.
//

import XCTest
@testable import AIAnalyzer

final class SarifReportTests: XCTestCase {

    func testCreatesSarifLogWithToolMetadataAndResults() {
        let report = SarifReport.make(from: [
            IssueReport(
                rule: "LargeClass",
                severity: Severity.warning.rawValue,
                message: "Type Demo is too large",
                file: "Sources/Demo.swift",
                line: 12,
                typeName: "Demo"
            )
        ])

        XCTAssertEqual(report.version, "2.1.0")
        XCTAssertEqual(report.runs.count, 1)
        XCTAssertEqual(report.runs[0].tool.driver.name, "AIAnalyzer")
        XCTAssertEqual(report.runs[0].tool.driver.rules.map(\.id), ["LargeClass"])
        XCTAssertEqual(report.runs[0].results.count, 1)
        XCTAssertEqual(report.runs[0].results[0].ruleId, "LargeClass")
        XCTAssertEqual(report.runs[0].results[0].level, "warning")
        XCTAssertEqual(report.runs[0].results[0].locations[0].physicalLocation.artifactLocation.uri, "Sources/Demo.swift")
        XCTAssertEqual(report.runs[0].results[0].locations[0].physicalLocation.region.startLine, 12)
    }

    func testDeduplicatesRulesButKeepsEveryResult() {
        let reports = [
            IssueReport(rule: "LargeClass", severity: Severity.warning.rawValue, message: "one", file: "A.swift", line: 1, typeName: "A"),
            IssueReport(rule: "LargeClass", severity: Severity.warning.rawValue, message: "two", file: "B.swift", line: 2, typeName: "B")
        ]

        let report = SarifReport.make(from: reports)

        XCTAssertEqual(report.runs[0].tool.driver.rules.map(\.id), ["LargeClass"])
        XCTAssertEqual(report.runs[0].results.count, 2)
    }

    func testMapsSeverityToSarifLevels() {
        let reports = [
            IssueReport(rule: "InfoRule", severity: Severity.info.rawValue, message: "info", file: "A.swift", line: nil, typeName: "A"),
            IssueReport(rule: "WarningRule", severity: Severity.warning.rawValue, message: "warning", file: "B.swift", line: nil, typeName: "B"),
            IssueReport(rule: "CriticalRule", severity: Severity.critical.rawValue, message: "critical", file: "C.swift", line: nil, typeName: "C")
        ]

        let levels = SarifReport.make(from: reports).runs[0].results.map(\.level)

        XCTAssertEqual(levels, ["note", "warning", "error"])
    }

    func testNilLineFallsBackToOne() {
        let report = SarifReport.make(from: [
            IssueReport(rule: "LargeClass", severity: Severity.warning.rawValue, message: "message", file: "Demo.swift", line: nil, typeName: "Demo")
        ])

        XCTAssertEqual(report.runs[0].results[0].locations[0].physicalLocation.region.startLine, 1)
    }
}
