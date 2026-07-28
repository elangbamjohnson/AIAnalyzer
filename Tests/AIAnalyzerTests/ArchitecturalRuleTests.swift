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

    func testCustomTypedThresholds() {
        let rule = LargeClassRule(vcMethods: 15, vcLines: 300)
        let vc = ClassInfo(type: .viewController, name: "MyVC", methodCount: 16, propertyCount: 5, lineCount: 200)
        
        let issue = rule.evaluate(vc)
        XCTAssertNotNil(issue)
        XCTAssertTrue(issue?.message.contains("16 methods (limit: 15)") == true)
    }

    func testConfigLoadingWithTypedThresholds() {
        let json = """
        {
            "rules": {
                "largeClass": {
                    "enabled": true,
                    "vcMethods": 15,
                    "vmLines": 200
                }
            }
        }
        """
        let data = json.data(using: .utf8)!
        let config = try? JSONDecoder().decode(AnalyzerConfig.self, from: data)
        XCTAssertNotNil(config)
        XCTAssertEqual(config?.rules?.largeClass?.vcMethods, 15)
        XCTAssertEqual(config?.rules?.largeClass?.vmLines, 200)
        XCTAssertNil(config?.rules?.largeClass?.vcLines)
    }
}
