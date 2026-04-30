//
//  AIConstants.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 30/04/26.
//

import Foundation

/// A collection of constant values used by the AI suggestion engine.
public enum AIConstants {
    /// Constants specific to the Gemini AI provider.
    public enum Gemini {
        /// The base URL for the Gemini API.
        public static let endpointBase = "https://generativelanguage.googleapis.com/v1beta/models"
        
        /// The default number of retry attempts for network requests.
        public static let defaultMaxRetryAttempts = 3
    }
    
    /// Global AI limits and defaults.
    public enum Defaults {
        /// Default maximum number of suggestions to generate.
        public static let maxSuggestions = 5
        
        /// Default maximum number of lines to include in context snippets.
        public static let snippetLineLimit = 120
    }
}
