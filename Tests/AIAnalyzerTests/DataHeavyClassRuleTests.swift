//
//  DataHeavyClassRuleTests.swift
//  AIAnalyzerTests
//

import XCTest
import SwiftParser
@testable import AIAnalyzer

final class DataHeavyClassRuleTests: XCTestCase {

    func testClassBelowThresholdProducesNoFinding() {
        let rule = DataHeavyClassRule(threshold: 5)
        let classInfo = ClassInfo(
            type: .model,
            name: "SmallDataModel",
            methodCount: 1,
            propertyCount: 4,
            lineCount: 20
        )
        let issue = rule.evaluate(classInfo)
        XCTAssertNil(issue)
    }

    func testClassAtThresholdBoundaryProducesNoFinding() {
        let rule = DataHeavyClassRule(threshold: 5)
        let classInfo = ClassInfo(
            type: .model,
            name: "BoundaryDataModel",
            methodCount: 1,
            propertyCount: 5,
            lineCount: 25
        )
        let issue = rule.evaluate(classInfo)
        XCTAssertNil(issue, "Class with property count exactly equal to threshold should not trigger a violation")
    }

    func testClassAboveThresholdTriggersFindingWithCorrectProperties() {
        let rule = DataHeavyClassRule(threshold: 5)
        let classInfo = ClassInfo(
            type: .model,
            name: "DataHeavyModel",
            methodCount: 2,
            propertyCount: 6,
            lineCount: 30
        )
        let issue = rule.evaluate(classInfo)

        XCTAssertNotNil(issue)
        XCTAssertEqual(issue?.ruleName, "DataHeavyClass")
        XCTAssertEqual(issue?.severity, .info)
        XCTAssertEqual(issue?.message, "Type DataHeavyModel has too many properties (6).")
        XCTAssertNil(issue?.line)
    }

    func testEmptyClassDoesNotCrashOrTriggerFinding() {
        let rule = DataHeavyClassRule(threshold: 5)
        let emptyClass = ClassInfo(
            type: .unknown,
            name: "EmptyClass",
            methodCount: 0,
            propertyCount: 0,
            lineCount: 2
        )
        let issue = rule.evaluate(emptyClass)
        XCTAssertNil(issue)
    }

    func testCustomThresholdIsRespected() {
        let customRule = DataHeavyClassRule(threshold: 2)
        let classInfo = ClassInfo(
            type: .model,
            name: "CustomModel",
            methodCount: 1,
            propertyCount: 3,
            lineCount: 15
        )
        let issue = customRule.evaluate(classInfo)

        XCTAssertNotNil(issue)
        XCTAssertEqual(issue?.severity, .info)
        XCTAssertEqual(issue?.message, "Type CustomModel has too many properties (3).")
    }

    func testConfigDecodingCustomThreshold() throws {
        let json = """
        {
            "rules": {
                "dataHeavyClass": {
                    "enabled": true,
                    "threshold": 3
                }
            }
        }
        """
        let data = Data(json.utf8)
        let config = try JSONDecoder().decode(AnalyzerConfig.self, from: data)
        let configuredThreshold = config.rules?.dataHeavyClass?.threshold ?? RuleConstants.dataHeavyClassThreshold
        XCTAssertEqual(configuredThreshold, 3)

        let rule = DataHeavyClassRule(threshold: configuredThreshold)
        let classInfo = ClassInfo(type: .model, name: "TestModel", methodCount: 0, propertyCount: 4, lineCount: 10)
        let issue = rule.evaluate(classInfo)
        XCTAssertNotNil(issue)
    }

    func testSwiftSourceCodeParsingFixture() {
        let source = """
        final class UserStateModel {
            var id: String = ""
            var name: String = ""
            var email: String = ""
            var age: Int = 0
            var isActive: Bool = false
            var avatarURL: String = ""
        }
        """
        let sourceFile = Parser.parse(source: source)
        let visitor = ClassVisitor(viewMode: .all)
        visitor.walk(sourceFile)

        XCTAssertEqual(visitor.classes.count, 1)
        let classInfo = visitor.classes[0]
        XCTAssertEqual(classInfo.name, "UserStateModel")
        XCTAssertEqual(classInfo.propertyCount, 6)

        let rule = DataHeavyClassRule(threshold: 5)
        let issue = rule.evaluate(classInfo)
        XCTAssertNotNil(issue)
        XCTAssertEqual(issue?.ruleName, "DataHeavyClass")
        XCTAssertEqual(issue?.severity, .info)
    }
}
