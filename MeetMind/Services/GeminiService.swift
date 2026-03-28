import Foundation

// MARK: - Gemini Service

@MainActor
class GeminiService: ObservableObject {
    static let shared = GeminiService()

    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        session = URLSession(configuration: config)
    }

    // MARK: - API Key

    func apiKey() throws -> String {
        // Try UserDefaults first
        let udKey = UserDefaults.standard.string(forKey: "geminiAPIKey") ?? ""
        if !udKey.isEmpty { return udKey }

        // Fall back to Secrets.plist
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let key = dict["GEMINI_API_KEY"] as? String,
           !key.isEmpty {
            return key
        }

        throw GeminiError.missingAPIKey
    }

    var hasAPIKey: Bool {
        (try? apiKey()) != nil
    }

    // MARK: - Generate Content

    /// Core method: calls Gemini generateContent endpoint
    func generateContent(
        model: String,
        systemInstruction: String,
        userContent: String,
        temperature: Double = 0.3,
        maxTokens: Int = 2000
    ) async throws -> String {
        let key = try apiKey()
        let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(key)")!

        var payload: [String: Any] = [
            "contents": [
                ["role": "user", "parts": [["text": userContent]]]
            ],
            "generationConfig": [
                "temperature": temperature,
                "maxOutputTokens": maxTokens,
                "topP": 0.95
            ]
        ]

        // Add system instruction
        if !systemInstruction.isEmpty {
            payload["systemInstruction"] = [
                "parts": [["text": systemInstruction]]
            ]
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await performRequest(request)
        try validateResponse(response, data: data)
        return try extractContent(data)
    }

    // MARK: - Chat About Meetings

    func chatAboutMeetings(query: String, meetingContext: String, model: String) async throws -> String {
        let profileContext = UserProfile.load().aiContextString
        let systemPrompt = """
        \(profileContext)

        You are MeetMind, a meeting intelligence assistant. Answer based ONLY on the meeting context provided.

        Rules:
        - Be direct and concise. Lead with the answer, not preamble.
        - Use **bold** for names, dates, and key terms.
        - Use bullet points for lists — never long paragraphs.
        - If the answer isn't in the context, say "I don't have that information in your meetings."
        - When referencing a meeting, mention its title in *italics*.
        - Keep responses under 200 words unless detail is requested.
        """

        let userText = "Meeting context:\n\n\(meetingContext)\n\n---\nUser question: \(query)"

        return try await generateContent(
            model: model,
            systemInstruction: systemPrompt,
            userContent: userText,
            temperature: 0.3,
            maxTokens: 2000
        )
    }

    // MARK: - Generate Meeting Brief Summary

    func generateSummary(
        model: String,
        systemPrompt: String,
        userContent: String,
        temperature: Double,
        maxTokens: Int
    ) async throws -> String {
        return try await generateContent(
            model: model,
            systemInstruction: systemPrompt,
            userContent: userContent,
            temperature: temperature,
            maxTokens: maxTokens
        )
    }

    // MARK: - Execute Recipe

    func executeRecipe(prompt: String, transcript: String, model: String) async throws -> String {
        return try await generateContent(
            model: model,
            systemInstruction: prompt,
            userContent: "Meeting transcript:\n\n\(transcript)",
            temperature: 0.3,
            maxTokens: 3000
        )
    }

    // MARK: - Private Helpers

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let maxRetries = 3
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                let (data, response) = try await session.data(for: request)

                if let http = response as? HTTPURLResponse {
                    if http.statusCode == 429 || (500...599).contains(http.statusCode) {
                        let delay = pow(2.0, Double(attempt))
                        print("[GeminiService] Retryable status \(http.statusCode), attempt \(attempt + 1)/\(maxRetries). Waiting \(delay)s...")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        lastError = http.statusCode == 429 ? GeminiError.rateLimited : GeminiError.serverError(http.statusCode)
                        continue
                    }
                }

                return (data, response)
            } catch let error as URLError where error.code == .timedOut {
                lastError = GeminiError.timeout
                if attempt < maxRetries - 1 {
                    let delay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
            } catch is GeminiError {
                throw lastError!
            } catch {
                lastError = GeminiError.networkError(error)
                if attempt < maxRetries - 1 {
                    let delay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
            }
        }

        throw lastError ?? GeminiError.networkError(NSError(domain: "GeminiService", code: -1))
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200...299:
            return
        case 400:
            // Parse Gemini error message for better diagnostics
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GeminiError.badRequest(message)
            }
            throw GeminiError.serverError(400)
        case 401, 403:
            throw GeminiError.unauthorized
        case 429:
            throw GeminiError.rateLimited
        case 500...599:
            throw GeminiError.serverError(http.statusCode)
        default:
            throw GeminiError.serverError(http.statusCode)
        }
    }

    private func extractContent(_ data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw GeminiError.decodingFailed("Unexpected Gemini response structure")
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Errors

enum GeminiError: LocalizedError {
    case missingAPIKey
    case unauthorized
    case rateLimited
    case badRequest(String)
    case serverError(Int)
    case decodingFailed(String)
    case networkError(Error)
    case timeout

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:         return "Gemini API key not found. Add it in Settings > AI Configuration."
        case .unauthorized:          return "Invalid Gemini API key. Please check your key in Settings."
        case .rateLimited:           return "Rate limited by Gemini. Please wait a moment and try again."
        case .badRequest(let msg):   return "Gemini request error: \(msg)"
        case .serverError(let code): return "Gemini server error (\(code)). Please try again."
        case .decodingFailed(let m): return "Failed to parse Gemini response: \(m)"
        case .networkError(let e):   return "Network error: \(e.localizedDescription)"
        case .timeout:               return "Request timed out. Please check your connection."
        }
    }
}
