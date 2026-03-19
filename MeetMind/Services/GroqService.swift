import Foundation

// MARK: - Result Types

struct TranscriptionResult {
    let text: String
    let segments: [TranscriptSegment]
}

struct TranscriptSegment: Codable {
    let start: Double
    let end: Double
    let text: String
}

struct MeetingBrief: Codable {
    let title: String
    let summary: String
    let decisions: [String]
    let actionItems: [BriefActionItem]
    let keyTopics: [String]
    let clientName: String?
    let keyQuotes: [String]?
}

struct BriefActionItem: Codable {
    let text: String
    let owner: String
    let due: String?
    let isMine: Bool
}

struct ParsedTodo: Codable {
    let task: String
    let dueDate: String?
    let priority: String?
    let assignee: String?
}

// MARK: - Errors

enum GroqError: LocalizedError {
    case missingAPIKey
    case invalidAudioFile
    case rateLimited
    case unauthorized
    case serverError(Int)
    case decodingFailed(String)
    case networkError(Error)
    case timeout

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:         return "Groq API key not found. Please add it in Settings."
        case .invalidAudioFile:      return "Audio file could not be read."
        case .rateLimited:           return "Rate limited by Groq. Please wait a moment and try again."
        case .unauthorized:          return "Invalid API key. Please check your Groq API key in Settings."
        case .serverError(let code): return "Groq server error (\(code)). Please try again."
        case .decodingFailed(let m): return "Failed to parse Groq response: \(m)"
        case .networkError(let e):   return "Network error: \(e.localizedDescription)"
        case .timeout:               return "Request timed out. Please check your connection."
        }
    }
}

// MARK: - Service

@MainActor
class GroqService: ObservableObject {
    static let shared = GroqService()

    private let whisperEndpoint = "https://api.groq.com/openai/v1/audio/transcriptions"
    private let chatEndpoint = "https://api.groq.com/openai/v1/chat/completions"

    private let whisperModel = "whisper-large-v3-turbo"
    private let llamaModel = "llama-3.3-70b-versatile"

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        session = URLSession(configuration: config)
    }

    // MARK: - API Key

    private func apiKey() throws -> String {
        // Try Keychain first
        if let key = KeychainService.load(), !key.isEmpty {
            return key
        }
        // Fall back to UserDefaults
        let udKey = UserDefaults.standard.string(forKey: "groqAPIKey") ?? ""
        if !udKey.isEmpty {
            return udKey
        }
        // Fall back to Secrets.plist
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let key = dict["GROQ_API_KEY"] as? String,
           !key.isEmpty {
            return key
        }
        throw GroqError.missingAPIKey
    }

    // MARK: - Whisper Transcription

    func transcribeAudio(fileURL: URL) async throws -> TranscriptionResult {
        let key = try apiKey()

        guard let audioData = try? Data(contentsOf: fileURL) else {
            throw GroqError.invalidAudioFile
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: whisperEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // file field
        body.appendMultipart(boundary: boundary, name: "file",
                             filename: fileURL.lastPathComponent,
                             mimeType: "audio/m4a", data: audioData)
        // model field
        body.appendMultipartField(boundary: boundary, name: "model", value: whisperModel)
        // response_format field
        body.appendMultipartField(boundary: boundary, name: "response_format", value: "verbose_json")

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await performRequest(request)
        try validateHTTPResponse(response)

        return try parseTranscriptionResponse(data)
    }

    // MARK: - Meeting Brief Generation

    func generateMeetingBrief(transcript: String, userNotes: String?, template: MeetingTemplate = .general) async throws -> MeetingBrief {
        let key = try apiKey()

        // Step 1: Generate rich markdown summary — use custom prompt from UserDefaults if available
        var summaryPrompt = customMeetingPrompt()

        // Append template-specific instructions if not general
        let templateModifier = template.promptModifier
        if !templateModifier.isEmpty {
            summaryPrompt += "\n\nAdditional context:\n\(templateModifier)"
        }

        var userContent = "Meeting transcript:\n\n\(transcript)"
        if let notes = userNotes, !notes.isEmpty {
            userContent += "\n\n---\nUser notes taken during meeting:\n\(notes)"
        }

        let summaryPayload: [String: Any] = [
            "model": llamaModel,
            "temperature": 0.3,
            "max_tokens": 4000,
            "messages": [
                ["role": "system", "content": summaryPrompt],
                ["role": "user", "content": userContent]
            ]
        ]

        let summaryData = try await chatCompletion(key: key, payload: summaryPayload)
        let richSummary = try extractChatContent(summaryData)

        // Step 2: Extract structured JSON for programmatic use (action items, client, topics)
        var jsonPrompt = """
        Extract structured data from this meeting transcript. Return ONLY valid JSON:
        {
            "title": "short descriptive meeting title",
            "decisions": ["decision 1", "decision 2"],
            "actionItems": [
                {"text": "task description", "owner": "person name", "due": "date or null", "isMine": true}
            ],
            "keyTopics": ["topic 1", "topic 2", "topic 3"],
            "clientName": "detected client/company name or null",
            "keyQuotes": ["Speaker: exact quote text", "Speaker: another notable quote"]
        }
        Rules: Only extract EXPLICIT commitments for action items. Set isMine=true for items the first speaker (user) committed to. Detect the primary client/company being discussed. Extract up to 3 notable or impactful direct quotes from the transcript, prefixed with the speaker name.
        """
        if !templateModifier.isEmpty {
            jsonPrompt += "\n\nAdditional extraction context:\n\(templateModifier)"
        }

        let jsonPayload: [String: Any] = [
            "model": llamaModel,
            "temperature": 0.1,
            "max_tokens": 800,
            "messages": [
                ["role": "system", "content": jsonPrompt],
                ["role": "user", "content": "Transcript:\n\n\(transcript)"]
            ]
        ]

        let jsonData = try await chatCompletion(key: key, payload: jsonPayload)
        let jsonContent = try extractChatContent(jsonData)

        // Parse the JSON extraction
        var brief: MeetingBrief
        do {
            brief = try decodeBrief(from: jsonContent)
        } catch {
            // Fallback: create brief from the rich summary
            brief = MeetingBrief(
                title: "Meeting Notes",
                summary: richSummary,
                decisions: [],
                actionItems: [],
                keyTopics: [],
                clientName: nil,
                keyQuotes: nil
            )
        }

        // Replace the short summary with the rich markdown summary
        brief = MeetingBrief(
            title: brief.title,
            summary: richSummary,
            decisions: brief.decisions,
            actionItems: brief.actionItems,
            keyTopics: brief.keyTopics,
            clientName: brief.clientName,
            keyQuotes: brief.keyQuotes
        )

        return brief
    }

    // MARK: - Todo Parsing

    func parseTodoFromVoice(transcript: String) async throws -> ParsedTodo {
        let key = try apiKey()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayStr = dateFormatter.string(from: Date())

        let calendarInfo: String = {
            let cal = Calendar.current
            let weekday = cal.component(.weekday, from: Date())
            let weekdayName = DateFormatter().weekdaySymbols[weekday - 1]
            return "Today is \(weekdayName), \(todayStr)."
        }()

        let systemPrompt = """
        You extract structured to-do items from natural language voice input.

        \(calendarInfo)

        Parse the user's speech and return ONLY valid JSON — no markdown, no backticks, no explanation. Just the raw JSON object:
        {"task": "clear task description", "dueDate": "YYYY-MM-DD or null", "priority": "high or medium or low or null", "assignee": "person name or null"}

        Date rules:
        - "tomorrow" = \(dateFormatter.string(from: Calendar.current.date(byAdding: .day, value: 1, to: Date())!))
        - "today" = \(todayStr)
        - "next week" = \(dateFormatter.string(from: Calendar.current.date(byAdding: .day, value: 7, to: Date())!))
        - "by Friday" = calculate the next Friday from today
        - If no date mentioned, set dueDate to "\(todayStr)" (default to today)

        Priority rules:
        - Words like "urgent", "important", "ASAP", "critical" = "high"
        - Words like "whenever", "no rush", "low priority" = "low"
        - Default = "medium"

        Task rules:
        - Clean up the task text — remove filler words like "um", "uh", "like", "you know"
        - Make it a clear, actionable task description
        - If a person is mentioned, extract them as assignee
        """

        let payload: [String: Any] = [
            "model": llamaModel,
            "temperature": 0.1,
            "max_tokens": 300,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": transcript]
            ]
        ]

        print("[GroqService] Parsing voice todo: \"\(transcript)\"")

        let data = try await chatCompletion(key: key, payload: payload)
        var content = try extractChatContent(data)
        print("[GroqService] Raw LLM response: \(content)")

        // Strip markdown code fences if LLM wrapped the JSON
        content = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = content.data(using: .utf8) else {
            // Fallback: create task from raw transcript
            print("[GroqService] Empty response, using raw transcript as task")
            return ParsedTodo(task: transcript, dueDate: todayStr, priority: "medium", assignee: nil)
        }

        do {
            let parsed = try JSONDecoder().decode(ParsedTodo.self, from: jsonData)
            print("[GroqService] Parsed todo: task=\(parsed.task), date=\(parsed.dueDate ?? "nil"), priority=\(parsed.priority ?? "nil")")
            return parsed
        } catch {
            print("[GroqService] JSON decode failed: \(error). Falling back to raw transcript.")
            // Fallback: use the transcript as-is
            return ParsedTodo(task: transcript, dueDate: todayStr, priority: "medium", assignee: nil)
        }
    }

    // MARK: - Chat About Meetings

    func chatAboutMeetings(query: String, meetingContext: String) async throws -> String {
        let key = try apiKey()

        let systemPrompt = """
        You are MeetMind, an AI assistant with access to the user's meeting transcripts and briefs. \
        Answer the user's question based ONLY on the meeting context provided. \
        If the answer isn't in the context, say so honestly. \
        When referencing information, mention which meeting it came from. \
        Be concise but thorough. Use bullet points for lists.
        """

        let payload: [String: Any] = [
            "model": llamaModel,
            "temperature": 0.3,
            "max_tokens": 2000,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "Meeting context:\n\n\(meetingContext)\n\n---\nUser question: \(query)"]
            ]
        ]

        let data = try await chatCompletion(key: key, payload: payload)
        return try extractChatContent(data)
    }

    // MARK: - Recipe Execution

    func executeRecipe(prompt: String, transcript: String) async throws -> String {
        let key = try apiKey()

        let payload: [String: Any] = [
            "model": llamaModel,
            "temperature": 0.3,
            "max_tokens": 3000,
            "messages": [
                ["role": "system", "content": prompt],
                ["role": "user", "content": "Meeting transcript:\n\n\(transcript)"]
            ]
        ]

        let data = try await chatCompletion(key: key, payload: payload)
        return try extractChatContent(data)
    }

    // MARK: - Participant Extraction

    func extractParticipants(transcript: String) async throws -> [DetectedParticipant] {
        let key = try apiKey()

        let systemPrompt = """
        Extract all participants/people mentioned in this meeting transcript. \
        Return ONLY valid JSON array (no markdown, no explanation):
        [
            {"name": "Full Name", "company": "Company Name or null", "role": "Role/Title or null"}
        ]
        Only include people who actively participated or were explicitly mentioned. \
        Detect company and role from context clues in the conversation.
        """

        let payload: [String: Any] = [
            "model": llamaModel,
            "temperature": 0.1,
            "max_tokens": 800,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": transcript]
            ]
        ]

        let data = try await chatCompletion(key: key, payload: payload)
        let content = try extractChatContent(data)

        var cleaned = content
        if cleaned.hasPrefix("```") {
            cleaned = cleaned
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw GroqError.decodingFailed("Empty participants response")
        }

        do {
            return try JSONDecoder().decode([DetectedParticipant].self, from: jsonData)
        } catch {
            throw GroqError.decodingFailed("Participants parse error: \(error.localizedDescription)")
        }
    }

    // MARK: - Follow-Up Email Generation

    func generateFollowUpEmail(brief: String, meetingTitle: String) async throws -> String {
        let key = try apiKey()

        let systemPrompt = """
        You are a professional email writer. Write a follow-up email based on the meeting brief provided. \
        The email should be clean plain text — no markdown symbols, no asterisks, no hashtags. \
        Include: a warm greeting, a brief recap of the meeting, key decisions made, action items with owners, \
        next steps, and a professional sign-off. Keep the tone professional but friendly. \
        Use proper paragraph spacing. Do NOT include a subject line — just the email body. \
        Replace the sender name with [Your Name] so the user can fill it in.
        """

        let payload: [String: Any] = [
            "model": llamaModel,
            "temperature": 0.4,
            "max_tokens": 1500,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "Meeting title: \(meetingTitle)\n\nMeeting brief:\n\(brief)"]
            ]
        ]

        let data = try await chatCompletion(key: key, payload: payload)
        return try extractChatContent(data)
    }

    // MARK: - Shared Network Helpers

    private func chatCompletion(key: String, payload: [String: Any]) async throws -> Data {
        var request = URLRequest(url: URL(string: chatEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await performRequest(request)
        try validateHTTPResponse(response)
        return data
    }

    /// Performs a request with automatic retry and exponential backoff for 429 and 5xx errors.
    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let maxRetries = 3
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                let (data, response) = try await session.data(for: request)

                if let http = response as? HTTPURLResponse {
                    // Retry on 429 (rate limited) or 5xx (server error)
                    if http.statusCode == 429 || (500...599).contains(http.statusCode) {
                        let delay = pow(2.0, Double(attempt)) // 1s, 2s, 4s
                        print("[GroqService] Retryable status \(http.statusCode), attempt \(attempt + 1)/\(maxRetries). Waiting \(delay)s...")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        lastError = http.statusCode == 429 ? GroqError.rateLimited : GroqError.serverError(http.statusCode)
                        continue
                    }
                }

                return (data, response)
            } catch let error as URLError where error.code == .timedOut {
                lastError = GroqError.timeout
                if attempt < maxRetries - 1 {
                    let delay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
            } catch is GroqError {
                throw lastError!
            } catch {
                lastError = GroqError.networkError(error)
                if attempt < maxRetries - 1 {
                    let delay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
            }
        }

        throw lastError ?? GroqError.networkError(NSError(domain: "GroqService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Max retries exceeded"]))
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200...299:
            return
        case 401:
            throw GroqError.unauthorized
        case 429:
            throw GroqError.rateLimited
        case 500...599:
            throw GroqError.serverError(http.statusCode)
        default:
            throw GroqError.serverError(http.statusCode)
        }
    }

    // MARK: - Custom Prompt

    /// Returns the user's custom meeting prompt from UserDefaults, or the built-in default.
    private func customMeetingPrompt() -> String {
        let saved = UserDefaults.standard.string(forKey: "customMeetingPrompt") ?? ""
        return saved.isEmpty ? PromptPresets.defaultPrompt : saved
    }

    // MARK: - Response Parsing

    private func parseTranscriptionResponse(_ data: Data) throws -> TranscriptionResult {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GroqError.decodingFailed("Invalid JSON from Whisper")
        }

        let text = json["text"] as? String ?? ""

        var segments: [TranscriptSegment] = []
        if let rawSegments = json["segments"] as? [[String: Any]] {
            for seg in rawSegments {
                let start = seg["start"] as? Double ?? 0
                let end = seg["end"] as? Double ?? 0
                let segText = seg["text"] as? String ?? ""
                segments.append(TranscriptSegment(start: start, end: end, text: segText))
            }
        }

        return TranscriptionResult(text: text, segments: segments)
    }

    private func extractChatContent(_ data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw GroqError.decodingFailed("Unexpected chat completion structure")
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func decodeBrief(from content: String) throws -> MeetingBrief {
        // Strip markdown code fences if the model wraps the JSON
        var cleaned = content
        if cleaned.hasPrefix("```") {
            cleaned = cleaned
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw GroqError.decodingFailed("Empty brief content")
        }

        do {
            return try JSONDecoder().decode(MeetingBrief.self, from: jsonData)
        } catch {
            throw GroqError.decodingFailed("Brief parse error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Data Multipart Helpers

private extension Data {
    mutating func appendMultipart(boundary: String, name: String, filename: String, mimeType: String, data: Data) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }

    mutating func appendMultipartField(boundary: String, name: String, value: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append("\(value)\r\n".data(using: .utf8)!)
    }
}
