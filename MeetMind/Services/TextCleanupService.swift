import Foundation

@MainActor
class TextCleanupService {
    static let shared = TextCleanupService()
    private let groq = GroqService.shared

    struct CleanupResult {
        let cleanedText: String
        let rawText: String
    }

    /// Clean up dictated text using Groq Llama: remove filler words, fix grammar, format.
    func cleanupDictatedText(_ rawText: String) async throws -> CleanupResult {
        let key = try groq.apiKey()

        let systemPrompt = """
        You are a text cleanup engine. Clean up dictated speech into polished text.

        RULES:
        1. Remove filler words: um, uh, like, you know, basically, literally, actually, so, well, right
        2. Remove false starts and repetitions
        3. Fix grammar and punctuation
        4. Maintain the speaker's intent and meaning exactly
        5. Format into clean paragraphs or bullet points where appropriate
        6. Do NOT add information that wasn't said
        7. Do NOT change the meaning or tone
        8. Keep it concise — remove verbal padding but keep substance

        Return ONLY the cleaned text. No explanations, no markdown wrapping, no quotes.
        """

        let requestBody: [String: Any] = [
            "model": "llama-3.3-70b-versatile",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": rawText]
            ],
            "temperature": 0.2,
            "max_tokens": 2000
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
              let content = message["content"] as? String else {
            throw GroqError.decodingFailed("Failed to parse text cleanup response")
        }

        return CleanupResult(
            cleanedText: content.trimmingCharacters(in: .whitespacesAndNewlines),
            rawText: rawText
        )
    }
}
