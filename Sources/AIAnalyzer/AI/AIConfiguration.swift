//
//  AIConfiguration.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 29/04/26.
//

import Foundation

/// `AIConfiguration` encapsulates all runtime settings that control the AI suggestion pipeline.
public struct AIConfiguration {
    /// Defines configuration specific to AI service providers (e.g., Gemini, Ollama).
    public struct AIServiceConfiguration {
        public let providerType: AIConstants.ProviderType
        public let model: String
        public let ollamaModel: String
        public let ollamaEndpoint: String
        public let apiKey: String?

        public init(
            providerType: AIConstants.ProviderType,
            model: String,
            ollamaModel: String,
            ollamaEndpoint: String,
            apiKey: String?
        ) {
            self.providerType = providerType
            self.model = model
            self.ollamaModel = ollamaModel
            self.ollamaEndpoint = ollamaEndpoint
            self.apiKey = apiKey
        }
    }

    /// Defines configuration for local AI models (e.g., Core ML).
    public struct AILocalModelConfiguration {
        public let localModelName: String
        public let localModelPath: String?

        public init(
            localModelName: String,
            localModelPath: String?
        ) {
            self.localModelName = localModelName
            self.localModelPath = localModelPath
        }
    }

    /// Feature flag that enables or disables the AI suggestion layer entirely.
    public let enabled: Bool
    /// Configuration related to AI service providers.
    public let serviceConfig: AIServiceConfiguration
    /// Configuration related to local AI models.
    public let localModelConfig: AILocalModelConfiguration
    /// Upper bound on AI suggestions generated per analyzed input.
    public let maxSuggestions: Int
    /// Maximum source lines included in the prompt context snippet.
    public let snippetLineLimit: Int

    /// Initializes a new AI configuration.
    public init(
        enabled: Bool,
        serviceConfig: AIServiceConfiguration,
        localModelConfig: AILocalModelConfiguration,
        maxSuggestions: Int,
        snippetLineLimit: Int
    ) {
        self.enabled = enabled
        self.serviceConfig = serviceConfig
        self.localModelConfig = localModelConfig
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

        let serviceConfig = AIServiceConfiguration(
            providerType: providerType,
            model: model,
            ollamaModel: ollamaModel,
            ollamaEndpoint: ollamaEndpoint,
            apiKey: apiKey
        )
        let localModelConfig = AILocalModelConfiguration(
            localModelName: localModelName,
            localModelPath: localModelPath
        )

        return AIConfiguration(
            enabled: enabled,
            serviceConfig: serviceConfig,
            localModelConfig: localModelConfig,
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
