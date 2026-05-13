//
//  RuleEngineTests.swift
//  AIAnalyzerTests
//
//  Created by Johnson Elangbam on 13/05/26.
//

import XCTest
@testable import AIAnalyzer

final class RuleEngineDedupTests: XCTestCase {

    func testGodObjectSuppressesRedundantStructuralIssues() {
        let engine = RuleEngine(
            rules: [
                LargeClassRule(),
                DataHeavyClassRule(),
                GodObjectRule()
            ]
        )

        let oversizedModel = ClassInfo(
            type: .model,
            name: "MonsterModel",
            methodCount: 30,
            propertyCount: 25,
            lineCount: 400
        )

        let issues = engine.analyze([oversizedModel])
        let ruleNames = Set(issues.map(\.ruleName))

        XCTAssertTrue(ruleNames.contains("GodObject"))
        XCTAssertFalse(ruleNames.contains("LargeClass"))
        XCTAssertFalse(ruleNames.contains("DataHeavyClass"))
        XCTAssertEqual(issues.count, 1)
    }
}
