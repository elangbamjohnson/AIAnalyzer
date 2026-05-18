//
//  HighMethodDensityRuleTests.swift
//  AIAnalyzerTests
//
//  Created by Johnson Elangbam on 13/05/26.
//

import XCTest
@testable import AIAnalyzer

final class DensityTests: XCTestCase {

    func testHighMethodDensity() {
        let rule = HighMethodDensityRule()
        let fragmentedClass = ClassInfo(type: .service, name: "SmallMethods", methodCount: 20, propertyCount: 2, lineCount: 40)
        let issue = rule.evaluate(fragmentedClass)

        XCTAssertNotNil(issue)
        XCTAssertEqual(issue?.ruleName, "HighMethodDensity")
    }

    func testDensityYieldToLargeClass() {
        let rule = HighMethodDensityRule()
        let hugeClass = ClassInfo(type: .viewController, name: "Huge", methodCount: 30, propertyCount: 5, lineCount: 500)
        XCTAssertNil(rule.evaluate(hugeClass))
    }
}
