//
//  LocalLLMProvider.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 30/04/26.
//

import Foundation
import CoreML

/// Local AI provider that prioritizes on-device inference and never requires network access.
///
/// Execution strategy:
/// 1. If a local model path is available, attempt Core ML inference.
/// 2. If model loading/inference fails and strict mode is disabled, fall back to heuristic guidance.
/// 3. If no model path exists, produce deterministic local guidance from static-analysis context.
///
/// This design keeps suggestions available even when model artifacts are missing or incompatible.
public struct LocalLLMProvider: AIProvider {
    /// Optional local model path supplied from environment/configuration.
    private let modelPath: String?

    /// The name of the model being used (e.g., Qwen2.5-Coder-7B-Instruct).
    private let modelName: String
    
    /// Strictness toggle:
    /// - `true`: throw errors when model path/inference is unavailable.
    /// - `false`: degrade gracefully to heuristic local suggestions.
    private let failIfStub: Bool

    /// Creates a local provider with optional strict behavior.
    /// - Parameters:
    ///   - modelPath: Path to local Core ML model artifact.
    ///   - modelName: The human-readable name of the model.
    ///   - failIfStub: Whether provider should fail instead of using heuristics.
    public init(modelPath: String?, modelName: String = AIConstants.Local.defaultModelName, failIfStub: Bool = false) {
        self.modelPath = modelPath
        self.modelName = modelName
        self.failIfStub = failIfStub
    }

    /// Produces an AI suggestion using model inference when possible, otherwise local heuristics.
    /// - Parameter context: Static-analysis payload for the current issue.
    /// - Returns: A synthesized `AISuggestion`.
    /// - Throws: `AIProviderError.localUnavailable` when strict mode is enabled and inference cannot run.
    public func suggest(for context: AIRequestContext) async throws -> AISuggestion {
        if failIfStub && modelPath == nil {
             throw AIProviderError.localUnavailable("No local model path provided for \(modelName) and failIfStub is enabled.")
        }

        // 1. Try to load and use a real CoreML model if path is provided
        if let path = modelPath {
            do {
                return try await performCoreMLInference(at: path, for: context)
            } catch {
                if failIfStub {
                    throw error
                }
                // Reliability fallback
                return generateLocalIntelligenceSuggestion(for: context, source: "Local Heuristics (Fallback from \(modelName))")
            }
        }

        // 2. If no model path is configured, use deterministic local intelligence.
        return generateLocalIntelligenceSuggestion(for: context, source: "Local Heuristics (\(modelName) Engine)")
    }

    /// Runs the Core ML inference path for text generation/refactoring guidance.
    ///
    /// The method validates model existence, loads/compiles it if required, and executes
    /// text inference. The model output is returned as the primary result. Heuristic fallback
    /// is handled by the caller only when this path fails.
    ///
    /// - Parameters:
    ///   - path: Filesystem path to model artifact.
    ///   - context: AI request context used to build the prompt.
    /// - Returns: Suggestion driven by model-generated output.
    private func performCoreMLInference(at path: String, for context: AIRequestContext) async throws -> AISuggestion {
        let url = URL(fileURLWithPath: path)
        do {
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw AIProviderError.localUnavailable("Model file not found at \(path)")
            }
            
            let model = try loadModel(from: url)
            let prompt = context.buildPrompt(compact: true)
            let outputText = try runTextInference(model: model, prompt: prompt)

            return AISuggestion(
                ruleName: context.issue.ruleName,
                className: context.classInfo?.name ?? "Unknown",
                severity: context.issue.severity,
                diagnosis: "Analysis complete using model at \(url.lastPathComponent).",
                modelSource: "Local Model (\(modelName))",
                suggestedRefactor: outputText
            )
        } catch {
            throw AIProviderError.localUnavailable("CoreML Error for \(modelName): \(error.localizedDescription)")
        }
    }

    /// Loads a Core ML model from either a compiled or source model artifact.
    ///
    /// - Note: Non-compiled models are compiled at runtime via `MLModel.compileModel(at:)`.
    /// - Parameter url: Model artifact URL.
    /// - Returns: Ready-to-infer `MLModel` instance.
    private func loadModel(from url: URL) throws -> MLModel {
        if url.pathExtension == "mlmodelc" {
            return try MLModel(contentsOf: url)
        }
        
        let compiledURL = try MLModel.compileModel(at: url)
        return try MLModel(contentsOf: compiledURL)
    }
    /// Executes text inference by mapping the prompt to the first available string input feature.
    ///
    /// It then extracts the first non-empty string output among predicted features.
    /// This generic mapping supports multiple text model signatures without hardcoding names.
    ///
    /// - Parameters:
    ///   - model: Loaded Core ML model.
    ///   - prompt: Prompt text to evaluate.
    /// - Returns: Model-generated output text.
    /// - Throws: `AIProviderError.localUnavailable` when required text features are unavailable.
    private func runTextInference(model: MLModel, prompt: String) throws -> String {
        let inputName = model.modelDescription.inputDescriptionsByName.first(where: { $0.value.type == .string })?.key
        guard let inputName else {
            throw AIProviderError.localUnavailable("Model does not expose a string input feature.")
        }
        
        let provider = try MLDictionaryFeatureProvider(dictionary: [inputName: prompt])
        let prediction = try model.prediction(from: provider)
        
        if let stringOutput = prediction.featureNames
            .compactMap({ prediction.featureValue(for: $0)?.stringValue })
            .first(where: { !$0.isEmpty }) {
            return stringOutput
        }
        
        throw AIProviderError.localUnavailable("Model prediction did not return a string output.")
    }

    /// Deterministic fallback engine that generates rule-specific refactor guidance.
    ///
    /// This path ensures useful output in fully offline scenarios or when model inference fails.
    /// - Parameters:
    ///   - context: Static analyzer context for the issue.
    ///   - source: The model source label to apply.
    /// - Returns: Rule-tailored `AISuggestion`.
    private func generateLocalIntelligenceSuggestion(for context: AIRequestContext, source: String) -> AISuggestion {
        let className = context.classInfo?.name ?? "Class"
        let rule = context.issue.ruleName
        
        var advice = ""
        let diagnosis = "Analysis of \(rule) violation."

        switch rule {
        case "GodObject":
            advice = """
            1) Root Cause: \(className) is handling too many responsibilities (UI, Data, Logic).
            2) Refactor Steps:
               - Extract networking logic into a Service class.
               - Move property-heavy state into a specialized Model or ViewModel.
               - Use a Coordinator for navigation logic.
            3) Quick Win: Move Delegate/DataSource implementations to extensions.
            """
        case "LargeClass":
            advice = """
            1) Root Cause: \(className) exceeds recommended line/method counts for its type.
            2) Refactor Steps:
               - Identify distinct functional blocks and move them to separate files.
               - Use composition instead of inheritance to share logic.
               - Audit methods: if a method doesn't use class state, move it to a Utility.
            3) Quick Win: Extract private helper methods into a support structure.
            """
        case "DataHeavyClass":
            advice = """
            1) Root Cause: High property-to-method ratio suggests this class is a 'Data Bucket'.
            2) Refactor Steps:
               - Convert to a 'Struct' if no identity or reference behavior is needed.
               - Group related properties into nested structs.
               - Move data processing logic into a dedicated Transformer or Manager.
            3) Quick Win: Encapsulate related properties into a single 'Configuration' object.
            """
        default:
            advice = "Local analysis suggests reviewing the SRP (Single Responsibility Principle) for \(className)."
        }

        return AISuggestion(
            ruleName: rule,
            className: className,
            severity: context.issue.severity,
            diagnosis: diagnosis,
            modelSource: source,
            suggestedRefactor: advice
        )
    }
}
