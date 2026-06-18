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
        public let cloudOptIn: Bool

        public init(
            providerType: AIConstants.ProviderType,
            model: String,
            ollamaModel: String,
            ollamaEndpoint: String,
            apiKey: String?,
            cloudOptIn: Bool
        ) {
            self.providerType = providerType
            self.model = model
            self.ollamaModel = ollamaModel
            self.ollamaEndpoint = ollamaEndpoint
            self.apiKey = apiKey
            self.cloudOptIn = cloudOptIn
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

    /// Prefer live process environment (`getenv`) so values applied via `setenv` (e.g. from `.aianalyzer.env`)
    /// are visible here; fall back to `ProcessInfo` snapshot when unset at the C layer.
    private static func environmentValue(for key: String) -> String? {
        if let ptr = getenv(key) {
            return String(cString: ptr)
        }
        return ProcessInfo.processInfo.environment[key]
    }

    /// Factory method that creates a configuration by reading environment variables.
    public static func fromEnvironment() -> AIConfiguration {
        let enabled = (environmentValue(for: "AI_ENABLED") ?? "false").lowercased() == "true"

        let providerRaw = environmentValue(for: "AI_PROVIDER") ?? "local"
        let providerType = AIConstants.ProviderType(rawValue: providerRaw.lowercased()) ?? .local

        // 1. Resolve and normalize Cloud Model (Gemini).
        let rawModel = environmentValue(for: "AI_MODEL") ?? "gemini-1.5-flash"
        let model = normalizeGeminiModel(rawModel)

        // 2. Resolve Local Model Name
        let localModelName = environmentValue(for: "AI_LOCAL_MODEL") ?? AIConstants.Local.defaultModelName

        // 3. Resolve Ollama settings (accept full chat URL or base host only).
        let ollamaModel = environmentValue(for: "OLLAMA_MODEL") ?? AIConstants.Ollama.defaultModelName
        let rawOllamaEndpoint = environmentValue(for: "OLLAMA_ENDPOINT") ?? AIConstants.Ollama.endpointBase
        let ollamaEndpoint = normalizeOllamaEndpoint(rawOllamaEndpoint)

        let apiKey = environmentValue(for: "GEMINI_API_KEY")
        let cloudOptIn = boolEnvironmentValue(for: "AI_CLOUD_OPT_IN")
        let localModelPath = normalizedOptionalPath(environmentValue(for: "AI_LOCAL_MODEL_PATH"))

        let maxSuggestions = Int(environmentValue(for: "AI_MAX_SUGGESTIONS") ?? "") ?? AIConstants.Defaults.maxSuggestions
        let snippetLineLimit = Int(environmentValue(for: "AI_SNIPPET_LINES") ?? "") ?? AIConstants.Defaults.snippetLineLimit

        let serviceConfig = AIServiceConfiguration(
            providerType: providerType,
            model: model,
            ollamaModel: ollamaModel,
            ollamaEndpoint: ollamaEndpoint,
            apiKey: apiKey,
            cloudOptIn: cloudOptIn
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

    private static func boolEnvironmentValue(for key: String) -> Bool {
        guard let raw = environmentValue(for: key) else {
            return false
        }

        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "true", "1", "yes", "y":
            return true
        default:
            return false
        }
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
