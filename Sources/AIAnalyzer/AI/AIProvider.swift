//
//  AIProvider.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 29/04/26.
//

import Foundation

/// `AIRequestContext` serves as the data transport object that carries the necessary context from
/// the static analysis engine to an AI provider.
///
/// It bundles the specific rule violation (Issue), the structural metadata of the affected class
/// (ClassInfo), and a relevant snippet of the source code. This allows the AI to understand
/// not just *what* went wrong, but the specific code environment in which it occurred.
public struct AIRequestContext {
    /// The specific code smell violation found by the static analyzer.
    public let issue: Issue
    
    /// Information about the class where the issue was detected.
    public let classInfo: ClassInfo?
    
    /// A string containing the relevant source code lines for context.
    public let sourceSnippet: String

    /// Initializes a new request context.
    /// - Parameters:
    ///   - issue: The rule violation.
    ///   - classInfo: Metadata about the target class.
    ///   - sourceSnippet: Source code context.
    public init(issue: Issue, classInfo: ClassInfo?, sourceSnippet: String) {
        self.issue = issue
        self.classInfo = classInfo
        self.sourceSnippet = sourceSnippet
    }
}

/// `AIProvider` defines the standard interface for any Large Language Model (LLM) backend.
///
/// By conforming to this protocol, a class or struct (like `GeminiProvider`) takes responsibility
/// for translating an `AIRequestContext` into a network request, interacting with a specific
/// AI API, and returning a structured `AISuggestion`. This abstraction allows the main
/// app to remain agnostic of the specific AI service being used.
public protocol AIProvider {
    /// Requests a refactoring suggestion based on the provided context.
    /// - Parameter context: The issue and source code details.
    /// - Returns: An `AISuggestion` containing the AI's response.
    /// - Throws: An `AIProviderError` if the request fails.
    func suggest(for context: AIRequestContext) async throws -> AISuggestion
}

/// `AIProviderError` encapsulates the various failure modes that can occur during
/// interaction with an AI service.
///
/// It categorizes errors into configuration issues, network failures, timeouts,
/// and data parsing errors, providing clear feedback to the user when the AI
/// component fails to deliver a suggestion.
public enum AIProviderError: Error {
    /// The configuration (e.g., URL or Key) is invalid.
    case invalidConfiguration(String)
    
    /// The network request failed with a specific message.
    case requestFailed(String)
    
    /// The request took longer than the allotted timeout.
    case timeout
    
    /// The provider returned data that could not be parsed.
    case invalidResponse
}

extension AIProviderError: LocalizedError {
    /// Human-readable description of the error.
    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message):
            return "Invalid AI configuration: \(message)"
        case .requestFailed(let message):
            return "AI request failed: \(message)"
        case .timeout:
            return "AI request timed out."
        case .invalidResponse:
            return "AI provider returned an invalid response."
        }
    }
}
