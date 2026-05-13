//
//  GodObjectRuleTests.swift
//  AIAnalyzerTests
//
//  Created by Johnson Elangbam on 13/05/26.
//

import XCTest
@testable import AIAnalyzer

final class GodObjectTests: XCTestCase {

    func testMultiSignalRequirement() {
        let rule = GodObjectRule()

        let oneSignal = ClassInfo(type: .viewController, name: "OneSignal", methodCount: 50, propertyCount: 5, lineCount: 100)
        XCTAssertNil(rule.evaluate(oneSignal))

        let twoSignals = ClassInfo(type: .viewController, name: "TwoSignals", methodCount: 45, propertyCount: 25, lineCount: 100)
        let issue = rule.evaluate(twoSignals)
        XCTAssertNotNil(issue)
        XCTAssertEqual(issue?.severity, .critical)
    }
}
