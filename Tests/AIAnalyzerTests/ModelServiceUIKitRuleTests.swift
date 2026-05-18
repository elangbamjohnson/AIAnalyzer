//
//  ModelServiceUIKitRuleTests.swift
//  AIAnalyzerTests
//
//  Created by Johnson Elangbam on 13/05/26.
//

import XCTest
@testable import AIAnalyzer

final class ModelServiceUIKitRuleTests: XCTestCase {

    func testModelWithUIKitImportIsViolation() {
        let rule = ModelServiceUIKitRule()
        let info = ClassInfo(
            type: .model,
            name: "UserModel",
            methodCount: 2,
            propertyCount: 3,
            lineCount: 40,
            imports: ["Foundation", "UIKit"]
        )
        let issue = rule.evaluate(info)
        XCTAssertNotNil(issue)
        XCTAssertEqual(issue?.ruleName, "ModelServiceUIKitViolation")
        XCTAssertEqual(issue?.severity, .critical)
        XCTAssertTrue(issue?.message.contains("UserModel") ?? false)
    }

    func testModelWithoutUIKitIsClean() {
        let rule = ModelServiceUIKitRule()
        let info = ClassInfo(
            type: .model,
            name: "UserModel",
            methodCount: 2,
            propertyCount: 3,
            lineCount: 40,
            imports: ["Foundation"]
        )
        XCTAssertNil(rule.evaluate(info))
    }

    func testServiceWithUIKitSubmoduleImportIsViolation() {
        let rule = ModelServiceUIKitRule()
        let info = ClassInfo(
            type: .service,
            name: "PaymentManager",
            methodCount: 5,
            propertyCount: 1,
            lineCount: 80,
            imports: ["UIKit.UIImage"]
        )
        let issue = rule.evaluate(info)
        XCTAssertNotNil(issue)
        XCTAssertTrue(issue?.message.contains("Service") ?? false)
    }

    func testViewModelWithUIKitIsNotEvaluatedByThisRule() {
        let rule = ModelServiceUIKitRule()
        let info = ClassInfo(
            type: .viewModel,
            name: "ProfileViewModel",
            methodCount: 4,
            propertyCount: 2,
            lineCount: 60,
            imports: ["UIKit"]
        )
        XCTAssertNil(rule.evaluate(info))
    }
}
