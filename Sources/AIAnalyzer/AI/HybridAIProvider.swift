//
//  HybridAIProvider.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 30/04/26.
//

import Foundation

/// Provider orchestrator that combines local inference and optional cloud escalation.
///
/// Reliability strategy:
/// - Prefer local to reduce network dependency and latency.
/// - Escalate to cloud when local output appears low-confidence.
/// - Degrade gracefully to local fallback if cloud is unavailable or fails.
public struct HybridAIProvider: AIProvider {
    /// Optional cloud provider used for escalation when available/configured.
    private let cloud: AIProvider?
    
    /// Strategy switch controlling whether local or cloud is attempted first.
    private let preferLocal: Bool

    /// Primary local provider used as first attempt in local-first mode.
    private let localPreferred: AIProvider

    /// Last-resort local provider used for graceful degradation.
    private let localFallback: AIProvider

    /// Creates a hybrid provider with explicit local/cloud components.
    /// - Parameters:
    ///   - localPreferred: Local provider used for first-pass suggestion generation.
    ///   - localFallback: Local provider used when other tiers fail.
    ///   - cloud: Optional cloud provider used for escalation/fallback.
    ///   - preferLocal: If `true`, executes local-first strategy; otherwise cloud-first.
    public init(
        localPreferred: AIProvider,
        localFallback: AIProvider,
        cloud: AIProvider?,
        preferLocal: Bool
    ) {
        self.cloud = cloud
        self.preferLocal = preferLocal
        self.localPreferred = localPreferred
        self.localFallback = localFallback
    }

    /// Routes request through configured orchestration strategy.
    /// - Parameter context: Issue context to convert into AI guidance.
    /// - Returns: Best-effort `AISuggestion` based on provider availability and confidence checks.
    public func suggest(for context: AIRequestContext) async throws -> AISuggestion {
        if preferLocal {
            return await runLocalFirstStrategy(for: context)
        } else {
            return await runCloudFirstStrategy(for: context)
        }
    }

    /// Local-first execution:
    /// 1. Try `localPreferred`.
    /// 2. If low-confidence, escalate to cloud when configured.
    /// 3. If local/cloud fail, return `localFallback` or static fallback payload.
    private func runLocalFirstStrategy(for context: AIRequestContext) async -> AISuggestion {
        do {
            let localSuggestion = try await localPreferred.suggest(for: context)
            
            // Phase 3: Tune reliability with a confidence check.
            // If the local suggestion is very short, it might be a placeholder or low-confidence result.
            if isHighConfidence(localSuggestion) {
                return localSuggestion
            }
            
            guard let cloud else {
                print("ℹ️ Local AI confidence low, but cloud is unavailable; using local fallback.")
                return (try? await localFallback.suggest(for: context)) ?? fallbackSuggestion(for: context)
            }
            
            print("ℹ️ Local AI confidence low for \(context.issue.ruleName); escalating to Gemini...")
            return try await cloud.suggest(for: context)
            
        } catch {
            if let cloud {
                print("⚠️ Local AI unavailable (\(error.localizedDescription)); falling back to Gemini...")
                do {
                    return try await cloud.suggest(for: context)
                } catch {
                    print("❌ Cloud fallback failed; using static local intelligence.")
                    return (try? await localFallback.suggest(for: context)) ?? fallbackSuggestion(for: context)
                }
            }

            print("⚠️ Local AI unavailable and cloud is not configured; using local fallback.")
            return (try? await localFallback.suggest(for: context)) ?? fallbackSuggestion(for: context)
        }
    }

    /// Cloud-first execution:
    /// 1. Try cloud provider when configured.
    /// 2. On error or missing cloud, use local fallback provider.
    private func runCloudFirstStrategy(for context: AIRequestContext) async -> AISuggestion {
        guard let cloud else {
            print("ℹ️ Cloud-first mode requested, but cloud is not configured; using local fallback.")
            return (try? await localFallback.suggest(for: context)) ?? fallbackSuggestion(for: context)
        }
        
        do {
            return try await cloud.suggest(for: context)
        } catch {
            print("⚠️ Gemini unavailable; falling back to local analysis...")
            return (try? await localFallback.suggest(for: context)) ?? fallbackSuggestion(for: context)
        }
    }

    /// Heuristic confidence gate for deciding whether local output is usable.
    ///
    /// Current implementation checks for minimum output length and excludes stub-like diagnoses.
    /// - Parameter suggestion: Candidate suggestion from local provider.
    /// - Returns: `true` when suggestion is detailed enough to skip cloud escalation.
    private func isHighConfidence(_ suggestion: AISuggestion) -> Bool {
        // Simple heuristic: if the suggested refactor is less than 50 characters, 
        // it's likely not detailed enough.
        return suggestion.suggestedRefactor.count > 50 && !suggestion.diagnosis.contains("Stub")
    }

    /// Creates a static safety-net suggestion when both local and cloud provider calls fail.
    /// - Parameter context: Original request context.
    /// - Returns: Minimal but actionable fallback guidance.
    private func fallbackSuggestion(for context: AIRequestContext) -> AISuggestion {
        return AISuggestion(
            ruleName: context.issue.ruleName,
            className: context.classInfo?.name ?? "Unknown",
            severity: context.issue.severity,
            diagnosis: "Analysis provided via basic static fallback.",
            suggestedRefactor: "Please review the SRP and architectural limits for \(context.issue.ruleName). Detailed AI suggestions are currently unavailable."
        )
    }
}
