//
//  TestAIProviderStubs.swift
//  AIAnalyzerTests
//
//  Created by Johnson Elangbam on 13/05/26.
//
//  Shared test doubles for AI provider and suggester tests.
//

import Foundation
@testable import AIAnalyzer

struct MockAIProvider: AIProvider {
    func suggest(for context: AIRequestContext) async throws -> AISuggestion {
        AISuggestion(
            metadata: .init(
                ruleName: context.issue.ruleName,
                typeName: context.classInfo?.name ?? "UnknownClass",
                severity: context.issue.severity
            ),
            content: .init(
                diagnosis: "mock diagnosis",
                modelSource: "MockProvider",
                suggestedRefactor: "mock refactor"
            )
        )
    }
}

struct ThrowingAIProvider: AIProvider {
    func suggest(for context: AIRequestContext) async throws -> AISuggestion {
        throw AIProviderError.localUnavailable("Simulated provider failure")
    }
}

struct StaticAIProvider: AIProvider {
    let diagnosis: String
    let suggestedRefactor: String
    let source: String = "StaticProvider"

    func suggest(for context: AIRequestContext) async throws -> AISuggestion {
        AISuggestion(
            metadata: .init(
                ruleName: context.issue.ruleName,
                typeName: context.classInfo?.name ?? "UnknownClass",
                severity: context.issue.severity
            ),
            content: .init(
                diagnosis: diagnosis,
                modelSource: source,
                suggestedRefactor: suggestedRefactor
            )
        )
    }
}
