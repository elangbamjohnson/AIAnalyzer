//
//  SourceRedactorTests.swift
//  AIAnalyzerTests
//
//  Created by Johnson Elangbam on 18/06/26.
//

import XCTest
@testable import AIAnalyzer

final class SourceRedactorTests: XCTestCase {

    func testRedactsCommonAssignmentSecrets() {
        let source = """
        let apiKey = "sk-live-secret"
        let password: String = 'hunter2'
        let normal = "visible"
        """

        let redacted = SourceRedactor.redact(source)

        XCTAssertFalse(redacted.contains("sk-live-secret"))
        XCTAssertFalse(redacted.contains("hunter2"))
        XCTAssertTrue(redacted.contains("[REDACTED]"))
        XCTAssertTrue(redacted.contains("visible"))
    }

    func testRedactsBearerTokens() {
        let source = #"headers["Authorization"] = "Bearer abcdefghijklmnop123456""#

        let redacted = SourceRedactor.redact(source)

        XCTAssertFalse(redacted.contains("abcdefghijklmnop123456"))
        XCTAssertTrue(redacted.contains("Bearer [REDACTED]"))
    }

    func testAISuggesterUsesRedactedSnippet() async {
        let provider = SnippetCapturingProvider()
        let suggester = AISuggester(provider: provider, maxSuggestions: 1, snippetLineLimit: 20)
        let issues = [
            Issue(ruleName: "LargeClass", message: "Class Demo warning", severity: .warning)
        ]
        let classes = [
            ClassInfo(type: .model, name: "Demo", methodCount: 1, propertyCount: 1, lineCount: 10)
        ]

        _ = await suggester.generateSuggestions(
            issues: issues,
            classes: classes,
            sourceCode: #"let token = "super-secret-token-value""#
        )

        XCTAssertEqual(provider.capturedSnippets.count, 1)
        XCTAssertFalse(provider.capturedSnippets[0].contains("super-secret-token-value"))
        XCTAssertTrue(provider.capturedSnippets[0].contains("[REDACTED]"))
    }
}

private final class SnippetCapturingProvider: AIProvider {
    private(set) var capturedSnippets: [String] = []

    func suggest(for context: AIRequestContext) async throws -> AISuggestion {
        capturedSnippets.append(context.sourceSnippet)
        return AISuggestion(
            metadata: .init(
                ruleName: context.issue.ruleName,
                typeName: context.classInfo?.name ?? "UnknownClass",
                severity: context.issue.severity
            ),
            content: .init(
                diagnosis: "captured",
                modelSource: "SnippetCapturingProvider",
                suggestedRefactor: "captured"
            )
        )
    }
}
