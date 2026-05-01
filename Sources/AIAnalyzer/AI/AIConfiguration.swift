//
//  AIConfiguration.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 29/04/26.
//

import Foundation

/// `AIConfiguration` encapsulates all runtime settings that control the AI suggestion pipeline.
///
/// It acts as a central source of truth for:
/// - Toggling the AI feature on or off.
/// - Selecting which provider strategy to use (`gemini`, `local`, or `hybrid`).
/// - Passing provider-specific inputs such as cloud model name/API key or local model path.
/// - Controlling request volume and prompt context size for predictable CLI output.
///
/// This configuration is typically initialized using the `fromEnvironment()` factory method,
/// which maps system environment variables to these properties, allowing for flexible
/// runtime adjustments without requiring code changes.
///


public struct AIConfiguration {
    /// Feature flag that enables or disables the AI suggestion layer entirely.
    public let enabled: Bool
    
    /// Strategy selector for provider orchestration.
    public let providerType: AIConstants.ProviderType
    
    /// Cloud model identifier used by remote providers (e.g., "gemini-1.5-flash").
    public let model: String

    /// The human-readable name or identifier for the local model.
    public let localModelName: String
    
    /// Cloud API key used to authenticate remote requests.
    public let apiKey: String?

    /// Filesystem path to a local Core ML model artifact.
    public let localModelPath: String?
    
    /// Upper bound on AI suggestions generated per analyzed input.
    public let maxSuggestions: Int
    
    /// Maximum source lines included in the prompt context snippet.
    public let snippetLineLimit: Int

    /// Initializes a new AI configuration.
    public init(
        enabled: Bool,
        providerType: AIConstants.ProviderType,
        model: String,
        localModelName: String,
        apiKey: String?,
        localModelPath: String?,
        maxSuggestions: Int,
        snippetLineLimit: Int
    ) {
        self.enabled = enabled
        self.providerType = providerType
        self.model = model
        self.localModelName = localModelName
        self.apiKey = apiKey
        self.localModelPath = localModelPath
        self.maxSuggestions = maxSuggestions
        self.snippetLineLimit = snippetLineLimit
    }

    /// Factory method that creates a configuration by reading environment variables.
    public static func fromEnvironment() -> AIConfiguration {
        let env = ProcessInfo.processInfo.environment
        let enabled = (env["AI_ENABLED"] ?? "false").lowercased() == "true"
        
        let providerRaw = env["AI_PROVIDER"] ?? "gemini"
        let providerType = AIConstants.ProviderType(rawValue: providerRaw.lowercased()) ?? .gemini
        
        // 1. Resolve and normalize Cloud Model (Gemini).
        let rawModel = env["AI_MODEL"] ?? "gemini-1.5-flash"
        let model = normalizeGeminiModel(rawModel)
        
        // 2. Resolve Local Model Name (Defaults to Qwen if not specified)
        let localModelName = env["AI_LOCAL_MODEL"] ?? AIConstants.Local.defaultModelName
        
        let apiKey = env["GEMINI_API_KEY"]
        let localModelPath = env["AI_LOCAL_MODEL_PATH"]
        
        let maxSuggestions = Int(env["AI_MAX_SUGGESTIONS"] ?? "") ?? AIConstants.Defaults.maxSuggestions
        let snippetLineLimit = Int(env["AI_SNIPPET_LINES"] ?? "") ?? AIConstants.Defaults.snippetLineLimit

        return AIConfiguration(
            enabled: enabled,
            providerType: providerType,
            model: model,
            localModelName: localModelName,
            apiKey: apiKey,
            localModelPath: localModelPath,
            maxSuggestions: maxSuggestions,
            snippetLineLimit: snippetLineLimit
        )
    }

    /// Normalizes user-provided Gemini model names into API-ready identifiers.
    ///
    /// Accepts common inputs such as:
    /// - `gemini-3-flash-preview`
    /// - `models/gemini-3-flash-preview`
    ///
    /// Returns a plain model id that can be safely appended after `/v1beta/models/`.
    private static func normalizeGeminiModel(_ rawModel: String) -> String {
        let trimmed = rawModel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "gemini-3-flash-preview"
        }

        let modelsPrefix = "models/"
        if trimmed.hasPrefix(modelsPrefix) {
            let normalized = String(trimmed.dropFirst(modelsPrefix.count))
            return normalized.isEmpty ? "gemini-3-flash-preview" : normalized
        }

        return trimmed
    }
}
