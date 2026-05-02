//
//  AIConfiguration.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 29/04/26.
//

import Foundation

/// `AIConfiguration` encapsulates all runtime settings that control the AI suggestion pipeline.
public struct AIConfiguration {
    /// Feature flag that enables or disables the AI suggestion layer entirely.
    public let enabled: Bool
    
    /// Strategy selector for provider orchestration.
    public let providerType: AIConstants.ProviderType
    
    /// Cloud model identifier used by remote providers (e.g., "gemini-1.5-flash").
    public let model: String

    /// The human-readable name or identifier for the local model.
    public let localModelName: String

    /// The model name specifically for Ollama.
    public let ollamaModel: String

    /// The base URL for the Ollama server.
    public let ollamaEndpoint: String
    
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
        ollamaModel: String,
        ollamaEndpoint: String,
        apiKey: String?,
        localModelPath: String?,
        maxSuggestions: Int,
        snippetLineLimit: Int
    ) {
        self.enabled = enabled
        self.providerType = providerType
        self.model = model
        self.localModelName = localModelName
        self.ollamaModel = ollamaModel
        self.ollamaEndpoint = ollamaEndpoint
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
        
        // 2. Resolve Local Model Name
        let localModelName = env["AI_LOCAL_MODEL"] ?? AIConstants.Local.defaultModelName
        
        // 3. Resolve Ollama settings (accept full chat URL or base host only).
        let ollamaModel = env["OLLAMA_MODEL"] ?? AIConstants.Ollama.defaultModelName
        let rawOllamaEndpoint = env["OLLAMA_ENDPOINT"] ?? AIConstants.Ollama.endpointBase
        let ollamaEndpoint = normalizeOllamaEndpoint(rawOllamaEndpoint)

        let apiKey = env["GEMINI_API_KEY"]
        let localModelPath = normalizedOptionalPath(env["AI_LOCAL_MODEL_PATH"])
        
        let maxSuggestions = Int(env["AI_MAX_SUGGESTIONS"] ?? "") ?? AIConstants.Defaults.maxSuggestions
        let snippetLineLimit = Int(env["AI_SNIPPET_LINES"] ?? "") ?? AIConstants.Defaults.snippetLineLimit

        return AIConfiguration(
            enabled: enabled,
            providerType: providerType,
            model: model,
            localModelName: localModelName,
            ollamaModel: ollamaModel,
            ollamaEndpoint: ollamaEndpoint,
            apiKey: apiKey,
            localModelPath: localModelPath,
            maxSuggestions: maxSuggestions,
            snippetLineLimit: snippetLineLimit
        )
    }

    private static func normalizeGeminiModel(_ rawModel: String) -> String {
        let trimmed = rawModel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "gemini-1.5-flash" }
        let modelsPrefix = "models/"
        if trimmed.hasPrefix(modelsPrefix) {
            return String(trimmed.dropFirst(modelsPrefix.count))
        }
        return trimmed
    }

    /// Treats blank `AI_LOCAL_MODEL_PATH` as unset so Core ML is not attempted with an empty path.
    private static func normalizedOptionalPath(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Ensures `OLLAMA_ENDPOINT` points at OpenAI-compatible chat completions.
    /// Accepts `http://host:11434` or the full `.../v1/chat/completions` URL.
    private static func normalizeOllamaEndpoint(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return AIConstants.Ollama.endpointBase
        }
        if trimmed.lowercased().contains("/v1/chat/completions") {
            return trimmed
        }
        var base = trimmed
        while base.hasSuffix("/") {
            base.removeLast()
        }
        return "\(base)/v1/chat/completions"
    }
}
