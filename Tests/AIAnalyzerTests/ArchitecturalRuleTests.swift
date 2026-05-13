//
//  ArchitecturalRuleTests.swift
//  AIAnalyzerTests
//
//  Created by Johnson Elangbam on 13/05/26.
//

import XCTest
@testable import AIAnalyzer

final class ArchitecturalTests: XCTestCase {

    func testContextAwareThresholds() {
        let rule = LargeClassRule()

        let vc = ClassInfo(type: .viewController, name: "MyVC", methodCount: 20, propertyCount: 5, lineCount: 200)
        XCTAssertNil(rule.evaluate(vc))

        let model = ClassInfo(type: .model, name: "MyModel", methodCount: 21, propertyCount: 2, lineCount: 50)
        let issue = rule.evaluate(model)
        XCTAssertNotNil(issue)
        XCTAssertEqual(issue?.severity, .critical)
    }
}
