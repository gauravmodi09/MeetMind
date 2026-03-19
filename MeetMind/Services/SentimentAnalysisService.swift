import Foundation
import NaturalLanguage

// MARK: - Sentiment Models

enum SentimentType: String, Codable {
    case positive = "Positive"
    case negative = "Negative"
    case neutral = "Neutral"
    case concern = "Concern"
}

struct SentimentHighlight: Identifiable {
    let id: UUID
    let text: String
    let score: Double
    let timestamp: Double
    let type: SentimentType

    init(
        id: UUID = UUID(),
        text: String,
        score: Double,
        timestamp: Double,
        type: SentimentType
    ) {
        self.id = id
        self.text = text
        self.score = score
        self.timestamp = timestamp
        self.type = type
    }
}

struct SentimentTimelineEntry {
    let timestamp: Double
    let score: Double
}

struct MeetingSentiment {
    let overallScore: Double
    let timeline: [SentimentTimelineEntry]
    let highlights: [SentimentHighlight]

    var overallLabel: String {
        if overallScore > 0.2 { return "Positive" }
        if overallScore < -0.2 { return "Negative" }
        return "Neutral"
    }

    var overallType: SentimentType {
        if overallScore > 0.2 { return .positive }
        if overallScore < -0.2 { return .negative }
        return .neutral
    }

    static let empty = MeetingSentiment(overallScore: 0, timeline: [], highlights: [])
}

// MARK: - Sentiment Analysis Service

@MainActor
final class SentimentAnalysisService {
    static let shared = SentimentAnalysisService()

    private let tagger = NLTagger(tagSchemes: [.sentimentScore])

    private init() {}

    // MARK: - Public API

    /// Analyze the sentiment of an entire meeting from its transcript and segments.
    func analyzeMeetingSentiment(
        transcript: String,
        segments: [TranscriptSegment]
    ) -> MeetingSentiment {
        guard !segments.isEmpty else {
            // Fall back to analyzing the raw transcript as a single block
            let score = sentimentScore(for: transcript)
            return MeetingSentiment(
                overallScore: score,
                timeline: [],
                highlights: []
            )
        }

        // 1. Score each segment
        var timeline: [SentimentTimelineEntry] = []
        var scoredSegments: [(segment: TranscriptSegment, score: Double)] = []

        for segment in segments {
            let trimmed = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let score = sentimentScore(for: trimmed)
            timeline.append(SentimentTimelineEntry(
                timestamp: segment.start,
                score: score
            ))
            scoredSegments.append((segment: segment, score: score))
        }

        // 2. Overall score: weighted average by segment text length
        let overallScore = weightedAverageScore(scoredSegments)

        // 3. Identify highlights (most positive, most negative, concerns)
        let highlights = extractHighlights(from: scoredSegments)

        return MeetingSentiment(
            overallScore: overallScore,
            timeline: timeline,
            highlights: highlights
        )
    }

    // MARK: - Private Helpers

    /// Use NLTagger to get a sentiment score for a piece of text. Returns -1.0 to 1.0.
    private func sentimentScore(for text: String) -> Double {
        tagger.string = text
        let (tag, _) = tagger.tag(
            at: text.startIndex,
            unit: .paragraph,
            scheme: .sentimentScore
        )
        guard let tag = tag, let score = Double(tag.rawValue) else { return 0.0 }
        return max(-1.0, min(1.0, score))
    }

    /// Weighted average where longer segments count more.
    private func weightedAverageScore(
        _ scored: [(segment: TranscriptSegment, score: Double)]
    ) -> Double {
        guard !scored.isEmpty else { return 0.0 }

        var totalWeight: Double = 0
        var weightedSum: Double = 0

        for entry in scored {
            let weight = Double(entry.segment.text.count)
            weightedSum += entry.score * weight
            totalWeight += weight
        }

        guard totalWeight > 0 else { return 0.0 }
        return max(-1.0, min(1.0, weightedSum / totalWeight))
    }

    /// Extract the most positive, most negative, and any concern-flagged segments.
    private func extractHighlights(
        from scored: [(segment: TranscriptSegment, score: Double)]
    ) -> [SentimentHighlight] {
        guard !scored.isEmpty else { return [] }

        var highlights: [SentimentHighlight] = []

        // Sort to find extremes
        let sorted = scored.sorted { $0.score > $1.score }

        // Most positive moments (top 3 with score > 0.2)
        let positives = sorted.prefix(3).filter { $0.score > 0.2 }
        for entry in positives {
            highlights.append(SentimentHighlight(
                text: entry.segment.text.trimmingCharacters(in: .whitespacesAndNewlines),
                score: entry.score,
                timestamp: entry.segment.start,
                type: .positive
            ))
        }

        // Most negative moments (bottom 3 with score < -0.2)
        let negatives = sorted.suffix(3).filter { $0.score < -0.2 }
        for entry in negatives {
            highlights.append(SentimentHighlight(
                text: entry.segment.text.trimmingCharacters(in: .whitespacesAndNewlines),
                score: entry.score,
                timestamp: entry.segment.start,
                type: .negative
            ))
        }

        // Flag concern moments: moderately negative (-0.6 to -0.2) that might indicate
        // hesitation, objections, or worry without being outright negative
        let concerns = scored.filter { $0.score < -0.1 && $0.score >= -0.5 }
            .sorted { $0.score < $1.score }
            .prefix(2)

        for entry in concerns {
            // Avoid duplicating anything already in negatives
            let alreadyAdded = highlights.contains { $0.timestamp == entry.segment.start }
            if !alreadyAdded {
                highlights.append(SentimentHighlight(
                    text: entry.segment.text.trimmingCharacters(in: .whitespacesAndNewlines),
                    score: entry.score,
                    timestamp: entry.segment.start,
                    type: .concern
                ))
            }
        }

        // Sort highlights by timestamp so they appear in meeting order
        return highlights.sorted { $0.timestamp < $1.timestamp }
    }
}
