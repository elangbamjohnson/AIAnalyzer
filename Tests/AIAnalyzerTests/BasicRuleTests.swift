//
//  BasicRuleTests.swift
//  AIAnalyzerTests
//
//  Created by Johnson Elangbam on 13/05/26.
//

import XCTest
@testable import AIAnalyzer

final class BasicRuleTests: XCTestCase {

    func testLargeClassRuleFallback() {
        let rule = LargeClassRule(threshold: 3)
        let classInfo = ClassInfo(type: .unknown, name: "TestClass", methodCount: 4, propertyCount: 1, lineCount: 10)
        let issue = rule.evaluate(classInfo)

        XCTAssertNotNil(issue)
        XCTAssertEqual(issue?.severity, .warning)
    }

    func testDataHeavyClassRule() {
        let rule = DataHeavyClassRule(threshold: 2)
        let classInfo = ClassInfo(type: .model, name: "TestData", methodCount: 1, propertyCount: 3, lineCount: 10)
        let issue = rule.evaluate(classInfo)

        XCTAssertNotNil(issue)
        XCTAssertEqual(issue?.ruleName, "DataHeavyClass")
    }
}
