//
//  AISuggesterFactory.swift
//  AIAnalyzer
//

import Foundation

/// Factory for building `AISuggester` instances based on runtime configuration.
enum AISuggesterFactory {
    /// Builds an `AISuggester` from runtime configuration and provider strategy.
    ///
    /// Provider selection rules:
    /// - `gemini`: requires `GEMINI_API_KEY`.
    /// - `local`: Core ML + heuristics (`AI_LOCAL_MODEL_PATH` optional).
    /// - `ollama`: local Ollama OpenAI-compatible API (`OLLAMA_MODEL`, `OLLAMA_ENDPOINT`).
    /// - `hybrid`: Ollama-first; escalates to Gemini when local confidence is low or Ollama fails; heuristic Core ML fallback as last resort.
    ///
    /// - Parameter configuration: Resolved AI runtime configuration.
    /// - Returns: Configured suggester or `nil` when AI is disabled/misconfigured.
    static func build(configuration: AIConfiguration) -> AISuggester? {
        guard configuration.enabled else {
            return nil
        }

        let provider: AIProvider

        switch configuration.serviceConfig.providerType {
        case .gemini:
            guard configuration.serviceConfig.cloudOptIn else {
                print("⚠️ AI_PROVIDER=gemini requires AI_CLOUD_OPT_IN=true because source snippets may leave this machine.")
                return nil
            }

            guard let apiKey = configuration.serviceConfig.apiKey, !apiKey.isEmpty else {
                print("⚠️ AI is set to 'gemini' but GEMINI_API_KEY is missing.")
                return nil
            }
            provider = GeminiProvider(apiKey: apiKey, model: configuration.serviceConfig.model)

        case .ollama:
            provider = OllamaProvider(endpoint: configuration.serviceConfig.ollamaEndpoint, modelName: configuration.serviceConfig.ollamaModel)

        case .local:
            if let warning = localProviderCoreMLDiagnostics(configuration: configuration) {
                print(warning)
            }
            provider = LocalLLMProvider(modelPath: configuration.localModelConfig.localModelPath, modelName: configuration.localModelConfig.localModelName)

        case .hybrid:
            let cloud: AIProvider?
            if configuration.serviceConfig.cloudOptIn,
               let apiKey = configuration.serviceConfig.apiKey,
               !apiKey.isEmpty {
                cloud = GeminiProvider(apiKey: apiKey, model: configuration.serviceConfig.model)
            } else {
                cloud = nil
                if configuration.serviceConfig.cloudOptIn {
                    print("ℹ️ Hybrid mode cloud escalation requested, but GEMINI_API_KEY is missing. Using local fallback path.")
                } else {
                    print("ℹ️ Hybrid mode running local-only. Set AI_CLOUD_OPT_IN=true to allow Gemini escalation.")
                }
            }

            // Prefer Ollama as the local tier in Hybrid mode
            let localPreferred = OllamaProvider(endpoint: configuration.serviceConfig.ollamaEndpoint, modelName: configuration.serviceConfig.ollamaModel)
            let localFallback = LocalLLMProvider(modelPath: nil, modelName: configuration.localModelConfig.localModelName, failIfStub: false)

            provider = HybridAIProvider(
                localPreferred: localPreferred,
                localFallback: localFallback,
                cloud: cloud,
                preferLocal: true
            )
        }

        return AISuggester(
            provider: provider,
            maxSuggestions: configuration.maxSuggestions,
            snippetLineLimit: configuration.snippetLineLimit
        )
    }

    /// Explains why `AI_PROVIDER=local` may still show heuristic output (Core ML vs Ollama).
    private static func localProviderCoreMLDiagnostics(configuration: AIConfiguration) -> String? {
        guard let path = configuration.localModelConfig.localModelPath else {
            return """
            ⚠️ AI_PROVIDER=local uses Core ML only (`LocalLLMProvider`), not Ollama.
               `AI_LOCAL_MODEL` is only a label; without a valid `AI_LOCAL_MODEL_PATH` (.mlmodelc), you get rule-based heuristics.
               For Qwen via Ollama: set AI_PROVIDER=ollama and OLLAMA_MODEL (e.g. qwen2.5-coder:7b).
            """
        }
        if !FileManager.default.fileExists(atPath: path) {
            return """
            ⚠️ AI_LOCAL_MODEL_PATH not found: \(path)
               Core ML inference will fail; output falls back to heuristics.
               Point to a real .mlmodelc bundle, or use AI_PROVIDER=ollama for your Qwen model.
            """
        }
        return nil
    }
}
