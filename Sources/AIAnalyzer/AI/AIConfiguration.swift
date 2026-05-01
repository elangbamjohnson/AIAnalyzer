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
    ///
    /// When `false`, no AI provider is created and analysis remains purely rule-based.
    public let enabled: Bool
    
    /// Strategy selector for provider orchestration.
    ///
    /// - `gemini`: cloud-only requests.
    /// - `local`: on-device inference/heuristics only.
    /// - `hybrid`: local-first with optional cloud escalation.
    public let providerType: AIConstants.ProviderType
    
    /// Cloud model identifier used by remote providers (for example Gemini variants).
    public let model: String
    
    /// Cloud API key used to authenticate remote requests.
    ///
    /// Optional because local-only and hybrid-without-cloud modes can operate without it.
    public let apiKey: String?

    /// Filesystem path to a local Core ML model artifact.
    ///
    /// Expected to point to a valid `.mlmodel`, `.mlpackage`, or compiled `.mlmodelc`.
    public let localModelPath: String?
    
    /// Upper bound on AI suggestions generated per analyzed input.
    ///
    /// This helps cap latency and keep provider calls predictable.
    public let maxSuggestions: Int
    
    /// Maximum source lines included in the prompt context snippet.
    ///
    /// Larger values may improve suggestion quality but increase payload size/cost.
    public let snippetLineLimit: Int

    /// Creates a strongly typed configuration object from resolved runtime values.
    ///
    /// This initializer does not perform validation; provider-specific validation happens
    /// when building concrete providers in the app bootstrap flow.
    public init(
        enabled: Bool,
        providerType: AIConstants.ProviderType,
        model: String,
        apiKey: String?,
        localModelPath: String?,
        maxSuggestions: Int,
        snippetLineLimit: Int
    ) {
        self.enabled = enabled
        self.providerType = providerType
        self.model = model
        self.apiKey = apiKey
        self.localModelPath = localModelPath
        self.maxSuggestions = maxSuggestions
        self.snippetLineLimit = snippetLineLimit
    }

    /// Builds configuration by reading process environment variables.
    ///
    /// Supported variables:
    /// - `AI_ENABLED`
    /// - `AI_PROVIDER`
    /// - `AI_MODEL`
    /// - `GEMINI_API_KEY`
    /// - `AI_LOCAL_MODEL_PATH`
    /// - `AI_MAX_SUGGESTIONS`
    /// - `AI_SNIPPET_LINES`
    ///
    /// Invalid or missing values are normalized to safe defaults.
    /// - Returns: A fully initialized `AIConfiguration`.
    public static func fromEnvironment() -> AIConfiguration {
        let env = ProcessInfo.processInfo.environment
        let enabled = (env["AI_ENABLED"] ?? "false").lowercased() == "true"
        
        let providerRaw = env["AI_PROVIDER"] ?? "gemini"
        let providerType = AIConstants.ProviderType(rawValue: providerRaw.lowercased()) ?? .gemini
        
        // Use Gemini for cloud-only, or Qwen as the base name for others
        let defaultModel = (providerType == .gemini) ? "gemini-1.5-flash" : AIConstants.Local.defaultModelName
        let model = env["AI_MODEL"] ?? defaultModel
        
        let apiKey = env["GEMINI_API_KEY"]
        let localModelPath = env["AI_LOCAL_MODEL_PATH"]
        
        let maxSuggestions = Int(env["AI_MAX_SUGGESTIONS"] ?? "") ?? AIConstants.Defaults.maxSuggestions
        let snippetLineLimit = Int(env["AI_SNIPPET_LINES"] ?? "") ?? AIConstants.Defaults.snippetLineLimit

        return AIConfiguration(
            enabled: enabled,
            providerType: providerType,
            model: model,
            apiKey: apiKey,
            localModelPath: localModelPath,
            maxSuggestions: maxSuggestions,
            snippetLineLimit: snippetLineLimit
        )
    }

}
