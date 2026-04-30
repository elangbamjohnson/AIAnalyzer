//
//  GeminiProvider.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 29/04/26.
//

import Foundation

/// `GeminiProvider` is the concrete implementation of the `AIProvider` protocol that leverages
/// Google's Gemini generative language models.
///
/// It handles the end-to-end lifecycle of an AI request, specifically:
/// - **Persona Engineering**: Designing a robust prompt that instructs the model to act as a
///   "Senior Swift Architect" to ensure technical accuracy and consistency.
/// - **Network Communication**: Managing the HTTP POST requests, including header configuration
///   and JSON payload serialization.
/// - **Resilience**: Implementing retry logic with exponential backoff to handle transient
///   failures like rate-limiting (HTTP 429) or temporary network interruptions.
/// - **Response Extraction**: Parsing the complex nested JSON structure returned by the Gemini
///   API into a simple, usable text string.
public struct GeminiProvider: AIProvider {
    /// The API key for authenticating with Google AI services.
    private let apiKey: String
    
    /// The model name to use (e.g., "gemini-1.5-flash").
    private let model: String
    
    /// Initializes a new Gemini provider.
    /// - Parameters:
    ///   - apiKey: The service API key.
    ///   - model: The model identifier.
    public init(apiKey: String, model: String) {
        self.apiKey = apiKey
        self.model = model
    }

    /// Generates a suggestion by calling the Gemini API.
    /// - Parameter context: The analysis context.
    /// - Returns: An `AISuggestion` populated with the API response.
    /// - Throws: `AIProviderError` on failure.
    public func suggest(for context: AIRequestContext) async throws -> AISuggestion {
        let className = context.classInfo?.name ?? "UnknownClass"
        let prompt = buildPrompt(context: context, className: className)
        let responseText = try await callGemini(prompt: prompt)

        return AISuggestion(
            ruleName: context.issue.ruleName,
            className: className,
            severity: context.issue.severity,
            diagnosis: "AI analysis generated for \(context.issue.ruleName).",
            suggestedRefactor: responseText
        )
    }

    /// Constructs the text prompt to be sent to the AI.
    /// - Parameters:
    ///   - context: The issue details and snippet.
    ///   - className: The target class name.
    /// - Returns: A formatted prompt string.
    private func buildPrompt(context: AIRequestContext, className: String) -> String {
        return """
        You are a senior Swift architect.
        Analyze this finding and provide concise, actionable refactor guidance.

        Rule: \(context.issue.ruleName)
        Severity: \(context.issue.severity.rawValue)
        Issue message: \(context.issue.message)
        Class: \(className)

        Code snippet:
        \(context.sourceSnippet)

        Return:
        1) Root cause (1-2 lines)
        2) Refactor steps (3-5 bullets)
        3) Quick win (1 bullet)
        """
    }

    /// Orchestrates the HTTP request to the Gemini API with retry logic.
    /// - Parameter prompt: The prompt to send.
    /// - Returns: The text response from the model.
    /// - Throws: `AIProviderError`.
    private func callGemini(prompt: String) async throws -> String {
        let endpoint = "\(AIConstants.Gemini.endpointBase)/\(model):generateContent?key=\(apiKey)"
        
        // Debug: Print the endpoint URL (masking the API key for security)
        let maskedKey = apiKey.prefix(4) + "..." + apiKey.suffix(4)
        let debugEndpoint = "\(AIConstants.Gemini.endpointBase)/\(model):generateContent?key=\(maskedKey)"
        print("🌐 Requesting AI suggestion from: \(debugEndpoint)")

        guard let url = URL(string: endpoint) else {
            throw AIProviderError.invalidConfiguration("Invalid Gemini URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        var lastError: AIProviderError = .invalidResponse
        let maxAttempts = AIConstants.Gemini.defaultMaxRetryAttempts
        for attempt in 1...maxAttempts {
            do {
                let data = try await performRequest(request)
                return try parseText(from: data)
            } catch let error as AIProviderError {
                lastError = error
                if shouldRetry(error: error), attempt < maxAttempts {
                    let backoffSeconds = pow(2.0, Double(attempt - 1))
                    try? await Task.sleep(nanoseconds: UInt64(backoffSeconds * 1_000_000_000))
                    continue
                }
                throw error
            }
        }

        throw lastError
    }

    /// Performs an asynchronous network request using `URLSession.shared.data(for:)`.
    /// - Parameter request: The URL request.
    /// - Returns: The raw data from the response.
    /// - Throws: `AIProviderError`.
    private func performRequest(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let code = (response as? HTTPURLResponse)?.statusCode, !(200...299).contains(code) {
                let bodyText = String(data: data, encoding: .utf8) ?? "<empty>"
                throw AIProviderError.requestFailed("HTTP \(code): \(bodyText)")
            }
            
            return data
        } catch let error as AIProviderError {
            throw error
        } catch {
            if let urlError = error as? URLError {
                throw AIProviderError.requestFailed("URL_ERROR \(urlError.code.rawValue): \(urlError.localizedDescription)")
            }
            throw AIProviderError.requestFailed(error.localizedDescription)
        }
    }

    /// Extracts the text content from the Gemini API JSON response.
    /// - Parameter data: The raw JSON data.
    /// - Returns: The extracted string.
    /// - Throws: `AIProviderError.invalidResponse`.
    private func parseText(from data: Data) throws -> String {
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let content = candidates.first?["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]],
            let text = parts.first?["text"] as? String
        else {
            throw AIProviderError.invalidResponse
        }

        return text
    }

    /// Determines if a failure is transient and should be retried.
    /// - Parameter error: The error encountered.
    /// - Returns: `true` if a retry should be attempted.
    private func shouldRetry(error: AIProviderError) -> Bool {
        guard case let .requestFailed(message) = error else {
            return false
        }
        let retryableHTTP = message.contains("HTTP 429") || message.contains("HTTP 503")
        let retryableNetwork =
            message.contains("URL_ERROR -1005") || // networkConnectionLost
            message.contains("URL_ERROR -1001") || // timedOut
            message.contains("URL_ERROR -1009") || // notConnectedToInternet
            message.contains("URL_ERROR -1003") || // cannotFindHost
            message.contains("URL_ERROR -1004") || // cannotConnectToHost
            message.contains("URL_ERROR -1200")    // secureConnectionFailed

        return retryableHTTP || retryableNetwork
    }
}
