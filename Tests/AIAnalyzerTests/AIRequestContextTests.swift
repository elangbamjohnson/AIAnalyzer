//
//  AIRequestContextTests.swift
//  AIAnalyzerTests
//
//  Created by Johnson Elangbam on 13/05/26.
//

import XCTest
@testable import AIAnalyzer

final class AIRequestContextPromptTests: XCTestCase {
    private let context = AIRequestContext(
        issue: Issue(ruleName: "LargeClass", message: "Demo issue", severity: .warning),
        classInfo: ClassInfo(type: .model, name: "Demo", methodCount: 20, propertyCount: 10, lineCount: 200),
        sourceSnippet: "class Demo { func foo() {} }"
    )

    func testStandardPromptContainsStructuralSections() {
        let prompt = context.buildPrompt(compact: false)

        XCTAssertTrue(prompt.contains("You are a senior Swift architect."))
        XCTAssertTrue(prompt.contains("Root cause"))
        XCTAssertTrue(prompt.contains("Refactor steps"))
        XCTAssertTrue(prompt.contains("Quick win"))
        XCTAssertTrue(prompt.contains("LargeClass"))
        XCTAssertTrue(prompt.contains("Demo"))
        XCTAssertTrue(prompt.contains("class Demo { func foo() {} }"))
    }

    func testCompactPromptExcludesStructuralSections() {
        let prompt = context.buildPrompt(compact: true)

        XCTAssertTrue(prompt.contains("You are a Swift refactoring assistant."))
        XCTAssertFalse(prompt.contains("You are a senior Swift architect."))
        XCTAssertFalse(prompt.contains("Root cause"))
        XCTAssertFalse(prompt.contains("Refactor steps"))
        XCTAssertFalse(prompt.contains("Quick win"))
        XCTAssertTrue(prompt.contains("LargeClass"))
        XCTAssertTrue(prompt.contains("Demo"))
        XCTAssertTrue(prompt.contains("class Demo { func foo() {} }"))
    }

    func testPromptDefaultsToStandardMode() {
        let prompt = context.buildPrompt()
        XCTAssertTrue(prompt.contains("You are a senior Swift architect."))
        XCTAssertTrue(prompt.contains("Root cause"))
    }
}
