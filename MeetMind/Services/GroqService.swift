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
    let openQuestions: [String]?
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

    func apiKey() throws -> String {
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

    /// Transcribes a single audio file via Groq Whisper with retry logic.
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
        // language hint — skips auto-detection, improves accuracy and speed
        body.appendMultipartField(boundary: boundary, name: "language", value: "en")
        // prompt hint — helps Whisper with domain vocabulary and reduces hallucination
        body.appendMultipartField(boundary: boundary, name: "prompt", value: "This is a professional business meeting recording. Speakers discuss projects, action items, deadlines, technical topics, and client requirements. Names and technical terms should be transcribed accurately.")
        // temperature — 0 for deterministic, most accurate transcription
        body.appendMultipartField(boundary: boundary, name: "temperature", value: "0")

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        // Use performRequest which already has retry logic for 429/5xx/timeout
        let (data, response) = try await performRequest(request)
        try validateHTTPResponse(response)

        return try parseTranscriptionResponse(data)
    }

    /// Transcribes multiple audio chunks and merges the results into one transcript.
    func transcribeChunks(fileURLs: [URL]) async throws -> TranscriptionResult {
        guard !fileURLs.isEmpty else { throw GroqError.invalidAudioFile }
        if fileURLs.count == 1 { return try await transcribeAudio(fileURL: fileURLs[0]) }

        var allText = ""
        var allSegments: [TranscriptSegment] = []
        var timeOffset: Double = 0

        for (index, url) in fileURLs.enumerated() {
            print("[GroqService] Transcribing chunk \(index + 1)/\(fileURLs.count)...")
            let result = try await transcribeAudio(fileURL: url)

            if !allText.isEmpty { allText += " " }
            allText += result.text

            // Offset segment timestamps to be continuous
            let offsetSegments = result.segments.map { seg in
                TranscriptSegment(start: seg.start + timeOffset, end: seg.end + timeOffset, text: seg.text)
            }
            allSegments.append(contentsOf: offsetSegments)

            // Next chunk's offset = this chunk's last segment end
            if let lastSeg = result.segments.last {
                timeOffset += lastSeg.end
            }
        }

        return TranscriptionResult(text: allText, segments: allSegments)
    }

    // MARK: - Transcript Cleaning

    /// Cleans raw transcript by removing filler words, repeated phrases, and normalizing whitespace.
    func cleanTranscript(_ text: String) -> String {
        var cleaned = text

        // Remove common filler words/sounds (only standalone, not part of words)
        let fillers = [
            "\\bum\\b", "\\buh\\b", "\\buhm\\b", "\\bhmm\\b", "\\bmm\\b",
            "\\byou know\\b", "\\blike,\\b", "\\bI mean,\\b", "\\bso,\\s*so\\b",
            "\\bbasically,\\b", "\\bactually,\\b", "\\bliterally,\\b"
        ]
        for filler in fillers {
            if let regex = try? NSRegularExpression(pattern: filler, options: .caseInsensitive) {
                cleaned = regex.stringByReplacingMatches(
                    in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: ""
                )
            }
        }

        // Remove stuttered words (e.g., "the the", "we we", "I I")
        if let stutter = try? NSRegularExpression(pattern: "\\b(\\w+)\\s+\\1\\b", options: .caseInsensitive) {
            cleaned = stutter.stringByReplacingMatches(
                in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "$1"
            )
        }

        // Normalize multiple spaces to single space
        if let multiSpace = try? NSRegularExpression(pattern: "\\s{2,}") {
            cleaned = multiSpace.stringByReplacingMatches(
                in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: " "
            )
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Validates transcript quality — returns true if usable, false if garbage.
    func isTranscriptUsable(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Too short = probably silence or noise
        if trimmed.count < 50 { return false }

        // Count actual words
        let words = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if words.count < 10 { return false }

        // Check for Whisper hallucination patterns (repeated phrases)
        let chunks = stride(from: 0, to: max(0, words.count - 5), by: 5).map { i in
            Array(words[i..<min(i + 5, words.count)]).joined(separator: " ").lowercased()
        }
        let uniqueChunks = Set(chunks)
        if chunks.count > 3 && Double(uniqueChunks.count) / Double(chunks.count) < 0.3 {
            // Over 70% repeated phrases — hallucination
            print("[GroqService] Transcript appears to be hallucinated (high repetition ratio)")
            return false
        }

        return true
    }

    // MARK: - Meeting Brief Generation

    func generateMeetingBrief(transcript: String, userNotes: String?, template: MeetingTemplate = .general) async throws -> MeetingBrief {
        let key = try apiKey()

        // Step 1: Generate rich markdown summary — use custom prompt from UserDefaults if available
        let profileContext = UserProfile.load().aiContextString
        var summaryPrompt = """
        \(profileContext)

        \(customMeetingPrompt())
        """

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

        // Step 2: Extract structured JSON — use the SUMMARY (not raw transcript) for consistency
        // This ensures the JSON data matches what the user sees in the summary
        var jsonPrompt = """
        \(profileContext)

        You are given a meeting summary. Extract structured data from it. Return ONLY valid JSON — no markdown, no explanation:
        {
            "title": "subject-style title like an email subject — describe WHAT was discussed, not when (max 8 words, e.g. 'Meyer Account POC Progress Review')",
            "decisions": ["decision 1", "decision 2"],
            "actionItems": [
                {"text": "clear task description", "owner": "person name", "due": "YYYY-MM-DD or null", "isMine": true}
            ],
            "keyTopics": ["topic 1", "topic 2", "topic 3"],
            "clientName": "detected client/company name or null",
            "keyQuotes": ["Speaker: exact notable quote", "Speaker: another impactful quote"],
            "openQuestions": ["Unresolved question 1", "Question needing follow-up"]
        }

        Rules:
        - Only extract EXPLICIT commitments as action items (not vague intentions)
        - Set isMine=true ONLY for items where the user/first speaker committed to do something
        - owner must be a specific person's name, not "Team" or "Everyone"
        - due dates must be in YYYY-MM-DD format; use null if no date mentioned
        - keyTopics: max 5, pick the most important themes
        - keyQuotes: max 3, pick quotes that are insightful or carry weight — not filler
        - clientName: the primary external client/company discussed, null if internal-only meeting
        - openQuestions: items raised but NOT resolved, max 5
        """
        if !templateModifier.isEmpty {
            jsonPrompt += "\n\nAdditional extraction context:\n\(templateModifier)"
        }

        let jsonPayload: [String: Any] = [
            "model": llamaModel,
            "temperature": 0.1,
            "max_tokens": 1200,
            "messages": [
                ["role": "system", "content": jsonPrompt],
                ["role": "user", "content": "Meeting summary:\n\n\(richSummary)\n\n---\nRaw transcript (for quotes only):\n\(String(transcript.prefix(4000)))"]
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
            print("[GroqService] JSON extraction failed, using fallback. Error: \(error)")
            brief = MeetingBrief(
                title: "Meeting Notes",
                summary: richSummary,
                decisions: [],
                actionItems: [],
                keyTopics: [],
                clientName: nil,
                keyQuotes: nil,
                openQuestions: nil
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
            keyQuotes: brief.keyQuotes,
            openQuestions: brief.openQuestions
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

        let profileContext = UserProfile.load().aiContextString
        let systemPrompt = """
        \(profileContext)

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

    // MARK: - Speaker Identification via LLM

    /// Asks the LLM to identify real speaker names from a labeled transcript.
    /// Returns a mapping from generic labels ("Speaker 1") to detected names ("Mitchell").
    func identifySpeakersFromTranscript(labeledTranscript: String, speakerCount: Int) async throws -> [String: String] {
        let key = try apiKey()

        let systemPrompt = """
        You are analyzing a meeting transcript where speakers are labeled as "Speaker 1", "Speaker 2", etc. \
        Your job is to identify the REAL names of each speaker using context clues such as:
        - Self-introductions ("Hi, I'm Mitchell", "This is Sarah speaking")
        - Others addressing them by name ("Thanks, John", "What do you think, Alice?")
        - Sign-offs or greetings that reveal names
        - Email addresses or references mentioned

        There are \(speakerCount) speaker(s) detected.

        Return ONLY valid JSON — no markdown, no explanation. Format:
        {"Speaker 1": "Real Name or Speaker 1", "Speaker 2": "Real Name or Speaker 2"}

        Rules:
        - If you can confidently identify a speaker's name, use it
        - If you cannot determine a name, keep the original label (e.g., "Speaker 1")
        - Do NOT guess names — only use names explicitly mentioned in context
        - Use the most complete form of the name available (e.g., "Mitchell Park" over just "Mitchell")
        """

        let payload: [String: Any] = [
            "model": llamaModel,
            "temperature": 0.1,
            "max_tokens": 500,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": labeledTranscript]
            ]
        ]

        let data = try await chatCompletion(key: key, payload: payload)
        let content = try extractChatContent(data)

        // Parse the JSON mapping
        var cleaned = content
        if cleaned.hasPrefix("```") {
            cleaned = cleaned
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let jsonData = cleaned.data(using: .utf8) else {
            print("[GroqService] Empty speaker identification response, returning empty mapping")
            return [:]
        }

        do {
            let mapping = try JSONDecoder().decode([String: String].self, from: jsonData)
            print("[GroqService] Speaker mapping: \(mapping)")
            return mapping
        } catch {
            print("[GroqService] Speaker identification parse error: \(error). Returning empty mapping.")
            return [:]
        }
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
