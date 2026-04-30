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
    
    /// The base URL for the Gemini API.
    private let endpointBase = "https://generativelanguage.googleapis.com/v1beta/models"
    
    /// The maximum number of retry attempts for failed requests.
    private let maxRetryAttempts = 3

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
    public func suggest(for context: AIRequestContext) throws -> AISuggestion {
        let className = context.classInfo?.name ?? "UnknownClass"
        let prompt = buildPrompt(context: context, className: className)
        let responseText = try callGemini(prompt: prompt)

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
    private func callGemini(prompt: String) throws -> String {
        guard let url = URL(string: "\(endpointBase)/\(model):generateContent?key=\(apiKey)") else {
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
        for attempt in 1...maxRetryAttempts {
            do {
                let data = try performRequest(request)
                return try parseText(from: data)
            } catch let error as AIProviderError {
                lastError = error
                if shouldRetry(error: error), attempt < maxRetryAttempts {
                    let backoffSeconds = pow(2.0, Double(attempt - 1))
                    Thread.sleep(forTimeInterval: backoffSeconds)
                    continue
                }
                throw error
            }
        }

        throw lastError
    }

    /// Performs a synchronous network request using `URLSession` and a semaphore.
    /// - Parameter request: The URL request.
    /// - Returns: The raw data from the response.
    /// - Throws: `AIProviderError`.
    private func performRequest(_ request: URLRequest) throws -> Data {
        let semaphore = DispatchSemaphore(value: 0)
        var resultData: Data?
        var resultError: Error?
        var statusCode: Int?

        URLSession.shared.dataTask(with: request) { data, response, error in
            resultData = data
            resultError = error
            statusCode = (response as? HTTPURLResponse)?.statusCode
            semaphore.signal()
        }.resume()

        let waitResult = semaphore.wait(timeout: .now() + 30)
        guard waitResult == .success else {
            throw AIProviderError.timeout
        }

        if let error = resultError {
            if let urlError = error as? URLError {
                throw AIProviderError.requestFailed("URL_ERROR \(urlError.code.rawValue): \(urlError.localizedDescription)")
            }
            throw AIProviderError.requestFailed(error.localizedDescription)
        }

        if let code = statusCode, !(200...299).contains(code) {
            let bodyText = resultData.flatMap { String(data: $0, encoding: .utf8) } ?? "<empty>"
            throw AIProviderError.requestFailed("HTTP \(code): \(bodyText)")
        }

        guard let data = resultData else {
            throw AIProviderError.invalidResponse
        }

        return data
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
