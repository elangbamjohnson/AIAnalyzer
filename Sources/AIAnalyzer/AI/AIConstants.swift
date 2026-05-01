//
//  AIConstants.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 30/04/26.
//

import Foundation

/// Shared constants used by AI provider configuration, networking, and defaults.
public enum AIConstants {
    /// Enumerates supported provider orchestration modes.
    ///
    /// These values are parsed from `AI_PROVIDER` and drive provider construction.
    public enum ProviderType: String {
        /// Cloud-only path using Gemini APIs.
        case gemini
        /// Local-only path using Core ML and heuristic fallbacks.
        case local
        /// Local-first path with optional cloud fallback.
        case hybrid
    }

    /// Namespaced constants for Gemini API communication.
    public enum Gemini {
        /// Base endpoint for Gemini model invocation.
        public static let endpointBase = "https://generativelanguage.googleapis.com/v1beta/models"
        
        /// Default retry count for transient network/provider failures.
        public static let defaultMaxRetryAttempts = 3
    }
    
    /// Namespaced constants for local on-device inference.
    public enum Local {
        /// Human-readable default model name used for documentation/UI messaging.
        public static let defaultModelName = "Llama-3-8B-Instruct"
    }
    
    /// Global defaults applied when environment values are missing or invalid.
    public enum Defaults {
        /// Fallback upper bound for suggestions generated per analysis run.
        public static let maxSuggestions = 5
        
        /// Fallback maximum source lines included in prompt context.
        public static let snippetLineLimit = 120
    }
}
