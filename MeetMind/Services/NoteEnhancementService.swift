import Foundation

@MainActor
class NoteEnhancementService {
    static let shared = NoteEnhancementService()
    private let groq = GroqService.shared

    struct EnhancementResult: Codable {
        let blocks: [EnhancedBlockJSON]
    }

    struct EnhancedBlockJSON: Codable {
        let text: String
        let isAI: Bool
        let citationTimestamp: String?
        let citationText: String?
    }

    func enhanceNotes(userNotes: String, transcript: String, template: MeetingTemplate) async throws -> [EnhancedBlock] {
        let key = try groq.apiKey()

        let profileContext = UserProfile.load().aiContextString
        let templateContext = template.promptModifier

        let systemPrompt = """
        \(profileContext)
        You are an AI note enhancement engine for MeetMind. Your job is to merge the user's raw meeting notes with the full transcript to create comprehensive, well-structured enhanced notes.

        RULES:
        1. Preserve ALL of the user's original notes verbatim — mark them with "isAI": false
        2. Add AI-generated content that fills gaps, adds context from the transcript, and structures the notes — mark with "isAI": true
        3. For each AI block, include a citation: the timestamp range and exact transcript text that supports it
        4. Structure the output with clear headings and bullet points
        5. Keep the user's voice and style — don't over-formalize their notes
        6. Add details the user missed but were discussed in the meeting
        \(templateContext.isEmpty ? "" : "\nTemplate context: \(templateContext)")

        OUTPUT FORMAT: Return a JSON object with this exact structure:
        {
          "blocks": [
            {"text": "## Meeting Summary", "isAI": true, "citationTimestamp": null, "citationText": null},
            {"text": "Discussed the Q3 roadmap", "isAI": false, "citationTimestamp": null, "citationText": null},
            {"text": "Sarah presented data showing 68% mobile usage.", "isAI": true, "citationTimestamp": "00:05:30-00:06:15", "citationText": "Sarah: 68% of our users are now on mobile..."}
          ]
        }

        Return ONLY valid JSON. No markdown wrapping.
        """

        let userMessage = """
        USER'S NOTES:
        \(userNotes)

        FULL TRANSCRIPT:
        \(transcript)
        """

        let requestBody: [String: Any] = [
            "model": "llama-3.3-70b-versatile",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage]
            ],
            "temperature": 0.3,
            "max_tokens": 4000,
            "response_format": ["type": "json_object"]
        ]

        var request = URLRequest(url: URL(string: "https://api.groq.com/openai/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw GroqError.serverError(statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String,
              let contentData = content.data(using: .utf8) else {
            throw GroqError.decodingFailed("Invalid enhancement response structure")
        }

        let result = try JSONDecoder().decode(EnhancementResult.self, from: contentData)

        return result.blocks.map { block in
            EnhancedBlock(
                text: block.text,
                isAI: block.isAI,
                citationRange: block.citationTimestamp,
                citationText: block.citationText
            )
        }
    }
}
