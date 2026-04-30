//
//  AIConfiguration.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 29/04/26.
//

import Foundation

/// `AIConfiguration` is responsible for managing the settings that control the AI-powered suggestion engine.
///
/// It acts as a central source of truth for:
/// - Toggling the AI feature on or off.
/// - Selecting the AI service provider and specific model version.
/// - Managing sensitive authentication data (API keys).
/// - Tuning the intensity of AI suggestions via caps and context window limits.
///
/// This configuration is typically initialized using the `fromEnvironment()` factory method,
/// which maps system environment variables to these properties, allowing for flexible
/// runtime adjustments without requiring code changes.
///


public struct AIConfiguration {
    /// Indicates whether the AI suggestion engine is enabled.
    public let enabled: Bool
    
    /// The AI provider to use (e.g., "gemini").
    public let provider: String
    
    /// The specific model identifier for the chosen provider.
    public let model: String
    
    /// The API key required to authenticate with the AI provider.
    public let apiKey: String?
    
    /// The maximum number of AI suggestions to generate per analysis session.
    public let maxSuggestions: Int
    
    /// The maximum number of lines from the source file to include in the AI prompt context.
    public let snippetLineLimit: Int

    /// Initializes a new AI configuration.
    /// - Parameters:
    ///   - enabled: Whether AI is active.
    ///   - provider: The provider name.
    ///   - model: The model version.
    ///   - apiKey: Optional API key.
    ///   - maxSuggestions: Cap on total suggestions.
    ///   - snippetLineLimit: Line limit for context snippets.
    public init(
        enabled: Bool,
        provider: String,
        model: String,
        apiKey: String?,
        maxSuggestions: Int,
        snippetLineLimit: Int
    ) {
        self.enabled = enabled
        self.provider = provider
        self.model = model
        self.apiKey = apiKey
        self.maxSuggestions = maxSuggestions
        self.snippetLineLimit = snippetLineLimit
    }

    /// Factory method that creates a configuration by reading environment variables.
    /// - Returns: An `AIConfiguration` populated from `ProcessInfo`.
    public static func fromEnvironment() -> AIConfiguration {
        let env = ProcessInfo.processInfo.environment
        let enabled = (env["AI_ENABLED"] ?? "false").lowercased() == "true"
        let provider = env["AI_PROVIDER"] ?? "gemini"
        let model = env["AI_MODEL"] ?? "gemini-3-flash-preview"
        let apiKey = env["GEMINI_API_KEY"]
        let maxSuggestions = Int(env["AI_MAX_SUGGESTIONS"] ?? "") ?? 5
        let snippetLineLimit = Int(env["AI_SNIPPET_LINES"] ?? "") ?? 120

        return AIConfiguration(
            enabled: enabled,
            provider: provider,
            model: model,
            apiKey: apiKey,
            maxSuggestions: maxSuggestions,
            snippetLineLimit: snippetLineLimit
        )
    }
}
