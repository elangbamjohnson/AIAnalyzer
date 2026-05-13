//
//  HybridAIProviderTests.swift
//  AIAnalyzerTests
//
//  Created by Johnson Elangbam on 13/05/26.
//

import XCTest
@testable import AIAnalyzer

final class HybridAIProviderTests: XCTestCase {
    private let demoContext = AIRequestContext(
        issue: Issue(ruleName: "LargeClass", message: "Demo issue", severity: .warning),
        classInfo: ClassInfo(type: .model, name: "Demo", methodCount: 20, propertyCount: 10, lineCount: 200),
        sourceSnippet: "class Demo {}"
    )

    func testLocalFirstUsesCloudWhenLocalConfidenceIsLow() async throws {
        let lowConfidenceLocal = StaticAIProvider(diagnosis: "Local low confidence", suggestedRefactor: "too short")
        let cloud = StaticAIProvider(diagnosis: "Cloud diagnosis", suggestedRefactor: "Detailed cloud recommendation for reliable fallback behavior.")
        let localFallback = StaticAIProvider(diagnosis: "Fallback diagnosis", suggestedRefactor: "Fallback recommendation text")

        let provider = HybridAIProvider(
            localPreferred: lowConfidenceLocal,
            localFallback: localFallback,
            cloud: cloud,
            preferLocal: true
        )

        let suggestion = try await provider.suggest(for: demoContext)
        XCTAssertEqual(suggestion.content.diagnosis, "Cloud diagnosis")
    }

    func testLocalFirstWithoutCloudFallsBackToLocalProvider() async throws {
        let failingLocal = ThrowingAIProvider()
        let localFallback = StaticAIProvider(
            diagnosis: "Local fallback diagnosis",
            suggestedRefactor: "A long and explicit local fallback recommendation with enough detail."
        )

        let provider = HybridAIProvider(
            localPreferred: failingLocal,
            localFallback: localFallback,
            cloud: nil,
            preferLocal: true
        )

        let suggestion = try await provider.suggest(for: demoContext)
        XCTAssertEqual(suggestion.content.diagnosis, "Local fallback diagnosis")
    }
}
