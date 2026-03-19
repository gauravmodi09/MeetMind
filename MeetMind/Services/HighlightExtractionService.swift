import Foundation

// MARK: - AudioHighlight Model

struct AudioHighlight: Identifiable {
    let id: UUID
    let timestamp: Double
    let text: String
    let category: HighlightCategory

    init(
        id: UUID = UUID(),
        timestamp: Double,
        text: String,
        category: HighlightCategory
    ) {
        self.id = id
        self.timestamp = timestamp
        self.text = text
        self.category = category
    }

    var formattedTimestamp: String {
        let minutes = Int(timestamp) / 60
        let seconds = Int(timestamp) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

enum HighlightCategory: String, CaseIterable {
    case decision = "Decision"
    case action = "Action"
    case question = "Question"
    case keyQuote = "Key Quote"

    var icon: String {
        switch self {
        case .decision:  return "checkmark.seal"
        case .action:    return "arrow.right.circle"
        case .question:  return "questionmark.circle"
        case .keyQuote:  return "quote.opening"
        }
    }
}

// MARK: - HighlightExtractionService

final class HighlightExtractionService {

    // MARK: - Keyword Patterns

    private static let decisionKeywords: [String] = [
        "decided", "agreed", "committed", "resolved", "confirmed",
        "approved", "finalized", "concluded", "settled on",
        "we'll go with", "the decision is", "let's go ahead",
        "moving forward with", "we're going with"
    ]

    private static let actionKeywords: [String] = [
        "by friday", "by monday", "by tuesday", "by wednesday",
        "by thursday", "by next week", "by end of day", "by eod",
        "by tomorrow", "by end of week",
        "i'll", "i will", "you should", "need to", "have to",
        "make sure to", "don't forget to", "responsible for",
        "take care of", "follow up", "send over", "schedule",
        "set up", "prepare", "deliver", "complete", "finish",
        "action item", "to-do", "todo", "assigned to"
    ]

    private static let nameCommitmentPatterns: [String] = [
        "will handle", "will take", "will own", "will lead",
        "is responsible", "will draft", "will send", "will review",
        "will prepare", "will schedule", "will follow up",
        "will reach out", "will coordinate"
    ]

    // MARK: - Public API

    /// Extract highlights from transcript segments using keyword matching.
    /// - Parameters:
    ///   - transcript: The full transcript text (used for context, optional).
    ///   - segments: Array of `TranscriptSegment` with timing info.
    /// - Returns: Array of `AudioHighlight` sorted by timestamp.
    static func extractHighlights(
        transcript: String?,
        segments: [TranscriptSegment]
    ) -> [AudioHighlight] {
        var highlights: [AudioHighlight] = []

        for segment in segments {
            let lower = segment.text.lowercased()
            let trimmed = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)

            // 1. Decision detection
            if matchesAny(text: lower, keywords: decisionKeywords) {
                highlights.append(AudioHighlight(
                    timestamp: segment.start,
                    text: truncateSnippet(trimmed),
                    category: .decision
                ))
                continue // one category per segment, prioritized
            }

            // 2. Action item detection
            if matchesAny(text: lower, keywords: actionKeywords) {
                highlights.append(AudioHighlight(
                    timestamp: segment.start,
                    text: truncateSnippet(trimmed),
                    category: .action
                ))
                continue
            }

            // 3. Name + commitment detection
            if matchesAny(text: lower, keywords: nameCommitmentPatterns) {
                highlights.append(AudioHighlight(
                    timestamp: segment.start,
                    text: truncateSnippet(trimmed),
                    category: .action
                ))
                continue
            }

            // 4. Question detection
            if trimmed.hasSuffix("?") && trimmed.count > 15 {
                highlights.append(AudioHighlight(
                    timestamp: segment.start,
                    text: truncateSnippet(trimmed),
                    category: .question
                ))
                continue
            }
        }

        return highlights.sorted { $0.timestamp < $1.timestamp }
    }

    // MARK: - Private Helpers

    private static func matchesAny(text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }

    private static func truncateSnippet(_ text: String, maxLength: Int = 120) -> String {
        guard text.count > maxLength else { return text }
        let end = text.index(text.startIndex, offsetBy: maxLength)
        return String(text[text.startIndex..<end]) + "..."
    }
}
