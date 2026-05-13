//
//  AISuggesterTests.swift
//  AIAnalyzerTests
//
//  Created by Johnson Elangbam on 13/05/26.
//

import XCTest
@testable import AIAnalyzer

final class AISuggesterTests: XCTestCase {

    func testGeneratesHighestSeveritySuggestionPerClassOnly() async {
        let suggester = AISuggester(provider: MockAIProvider(), maxSuggestions: 10, snippetLineLimit: 20)
        let classes = [ClassInfo(type: .model, name: "Demo", methodCount: 1, propertyCount: 1, lineCount: 10)]
        let issues = [
            Issue(ruleName: "InfoRule", message: "Class Demo info", severity: .info),
            Issue(ruleName: "WarnRule", message: "Class Demo warning", severity: .warning),
            Issue(ruleName: "CriticalRule", message: "Class Demo critical", severity: .critical)
        ]

        let suggestions = await suggester.generateSuggestions(
            issues: issues,
            classes: classes,
            sourceCode: "class Demo {}"
        )

        XCTAssertEqual(suggestions.count, 1)
        XCTAssertFalse(suggestions.map(\.metadata.ruleName).contains("WarnRule"))
        XCTAssertTrue(suggestions.map(\.metadata.ruleName).contains("CriticalRule"))
    }

    func testGeneratesPerClassSuggestionsAcrossDifferentClasses() async {
        let suggester = AISuggester(provider: MockAIProvider(), maxSuggestions: 10, snippetLineLimit: 20)
        let classes = [
            ClassInfo(type: .model, name: "Demo", methodCount: 1, propertyCount: 1, lineCount: 10),
            ClassInfo(type: .service, name: "Worker", methodCount: 1, propertyCount: 1, lineCount: 10)
        ]
        let issues = [
            Issue(ruleName: "DemoWarn", message: "Class Demo warning", severity: .warning),
            Issue(ruleName: "DemoCritical", message: "Class Demo critical", severity: .critical),
            Issue(ruleName: "WorkerWarn", message: "Class Worker warning", severity: .warning)
        ]

        let suggestions = await suggester.generateSuggestions(
            issues: issues,
            classes: classes,
            sourceCode: "class Demo {} class Worker {}"
        )

        XCTAssertEqual(suggestions.count, 2)
        XCTAssertTrue(suggestions.map(\.metadata.ruleName).contains("DemoCritical"))
        XCTAssertTrue(suggestions.map(\.metadata.ruleName).contains("WorkerWarn"))
    }
}
