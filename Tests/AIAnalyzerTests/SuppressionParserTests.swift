//
//  SuppressionParserTests.swift
//  AIAnalyzerTests
//
//  Created by Johnson Elangbam on 18/06/26.
//

import XCTest
@testable import AIAnalyzer

final class SuppressionParserTests: XCTestCase {

    func testParsesSingleRuleSuppression() {
        let source = """
        // aianalyzer:disable LargeClass
        final class Demo {}
        """

        XCTAssertEqual(SuppressionParser.suppressedRuleNames(in: source), ["LargeClass"])
    }

    func testParsesMultipleRuleSuppression() {
        let source = """
        // aianalyzer:disable LargeClass, GodObject
        final class Demo {}
        """

        XCTAssertEqual(SuppressionParser.suppressedRuleNames(in: source), ["LargeClass", "GodObject"])
    }

    func testFiltersSuppressedIssuesCaseInsensitively() {
        let issues = [
            Issue(ruleName: "LargeClass", message: "large", severity: .warning),
            Issue(ruleName: "GodObject", message: "god", severity: .critical)
        ]

        let filtered = SuppressionParser.filter(issues, suppressedRuleNames: ["largeclass"])

        XCTAssertEqual(filtered.map(\.ruleName), ["GodObject"])
    }

    func testIgnoresDirectiveInsideStringLiteral() {
        let source = """
        let text = "aianalyzer:disable LargeClass"
        final class Demo {}
        """

        XCTAssertTrue(SuppressionParser.suppressedRuleNames(in: source).isEmpty)
    }

    func testIgnoresCommentDirectiveInsideStringLiteral() {
        let source = """
        let text = "// aianalyzer:disable LargeClass"
        final class Demo {}
        """

        XCTAssertTrue(SuppressionParser.suppressedRuleNames(in: source).isEmpty)
    }

    func testAllSuppressionFiltersEveryIssue() {
        let issues = [
            Issue(ruleName: "LargeClass", message: "large", severity: .warning),
            Issue(ruleName: "DataHeavyClass", message: "data", severity: .info)
        ]

        XCTAssertTrue(SuppressionParser.filter(issues, suppressedRuleNames: ["all"]).isEmpty)
    }

    func testAllSuppressionIsCaseInsensitive() {
        let issues = [
            Issue(ruleName: "LargeClass", message: "large", severity: .warning),
            Issue(ruleName: "DataHeavyClass", message: "data", severity: .info)
        ]

        XCTAssertTrue(SuppressionParser.filter(issues, suppressedRuleNames: ["All"]).isEmpty)
    }
}
