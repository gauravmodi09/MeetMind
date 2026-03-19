import Foundation

// MARK: - Speaker Segment

struct SpeakerSegment: Identifiable {
    let id: UUID
    let speaker: String
    let start: Double
    let end: Double
    let text: String

    init(
        id: UUID = UUID(),
        speaker: String,
        start: Double,
        end: Double,
        text: String
    ) {
        self.id = id
        self.speaker = speaker
        self.start = start
        self.end = end
        self.text = text
    }
}

// MARK: - Speaker Identification Result

struct SpeakerIdentificationResult {
    let segments: [SpeakerSegment]
    let speakerCount: Int

    /// All unique speaker labels in order of first appearance.
    var speakerLabels: [String] {
        var seen = Set<String>()
        var labels: [String] = []
        for segment in segments {
            if !seen.contains(segment.speaker) {
                seen.insert(segment.speaker)
                labels.append(segment.speaker)
            }
        }
        return labels
    }
}

// MARK: - Service

@MainActor
class SpeakerIdentificationService: ObservableObject {
    static let shared = SpeakerIdentificationService()

    /// Minimum gap between segments (in seconds) to suggest a speaker change.
    private let gapThreshold: Double = 1.5

    /// Sentence-ending punctuation that, combined with a pause, strongly suggests a new speaker.
    private let sentenceEnders: Set<Character> = [".", "!", "?"]

    /// Shorter gap threshold when the previous segment ends with sentence-ending punctuation.
    private let sentenceEndGapThreshold: Double = 0.8

    private init() {}

    // MARK: - Heuristic Speaker Detection

    /// Analyzes transcript segments and assigns speaker labels based on timing heuristics.
    ///
    /// Since Whisper does not provide native diarization, this uses:
    /// - Timestamp gaps > 1.5s suggest a speaker change
    /// - Sentence-ending patterns + pause > 0.8s = likely new speaker
    /// - Labels assigned as "Speaker 1", "Speaker 2", etc.
    func identifySpeakers(from segments: [TranscriptSegment]) -> SpeakerIdentificationResult {
        guard !segments.isEmpty else {
            return SpeakerIdentificationResult(segments: [], speakerCount: 0)
        }

        var speakerSegments: [SpeakerSegment] = []
        var currentSpeakerIndex = 1

        // First segment is always Speaker 1
        let firstSeg = segments[0]
        speakerSegments.append(SpeakerSegment(
            speaker: "Speaker 1",
            start: firstSeg.start,
            end: firstSeg.end,
            text: firstSeg.text.trimmingCharacters(in: .whitespaces)
        ))

        for i in 1..<segments.count {
            let previous = segments[i - 1]
            let current = segments[i]

            let gap = current.start - previous.end
            let previousText = previous.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let endsWithSentence = !previousText.isEmpty && sentenceEnders.contains(previousText.last!)

            let isSpeakerChange: Bool
            if gap >= gapThreshold {
                // Large gap — strong signal of speaker change
                isSpeakerChange = true
            } else if endsWithSentence && gap >= sentenceEndGapThreshold {
                // Sentence ended + moderate pause — likely speaker change
                isSpeakerChange = true
            } else {
                isSpeakerChange = false
            }

            let speakerLabel: String
            if isSpeakerChange {
                // Alternate between speakers; for multi-speaker detection, cycle through
                let previousSpeaker = speakerSegments.last?.speaker ?? "Speaker 1"
                let previousIndex = speakerIndexFromLabel(previousSpeaker)

                // Simple two-speaker alternation for basic heuristic;
                // if gap is very large (>5s), potentially a new/third speaker
                if gap > 5.0 && currentSpeakerIndex < 6 {
                    // Check if this might be a new speaker we haven't seen
                    // Only introduce a new speaker if the gap is significantly large
                    currentSpeakerIndex += 1
                    speakerLabel = "Speaker \(currentSpeakerIndex)"
                } else {
                    // Alternate: pick a different speaker than the previous one
                    let nextIndex = previousIndex == 1 ? 2 : 1
                    if nextIndex > currentSpeakerIndex {
                        currentSpeakerIndex = nextIndex
                    }
                    speakerLabel = "Speaker \(nextIndex)"
                }
            } else {
                // Same speaker continues
                speakerLabel = speakerSegments.last?.speaker ?? "Speaker 1"
            }

            speakerSegments.append(SpeakerSegment(
                speaker: speakerLabel,
                start: current.start,
                end: current.end,
                text: current.text.trimmingCharacters(in: .whitespaces)
            ))
        }

        // Merge consecutive segments from the same speaker
        let merged = mergeConsecutiveSpeakerSegments(speakerSegments)

        let uniqueSpeakers = Set(merged.map { $0.speaker })
        return SpeakerIdentificationResult(segments: merged, speakerCount: uniqueSpeakers.count)
    }

    // MARK: - LLM-Enhanced Speaker Identification

    /// Uses Groq LLM to identify speakers by name from context clues in the transcript,
    /// then maps those names back onto the heuristic speaker segments.
    func identifySpeakersWithLLM(from segments: [TranscriptSegment]) async throws -> SpeakerIdentificationResult {
        // Step 1: Run heuristic detection first
        let heuristicResult = identifySpeakers(from: segments)

        guard heuristicResult.speakerCount > 0 else {
            return heuristicResult
        }

        // Step 2: Build a labeled transcript for the LLM
        let labeledTranscript = heuristicResult.segments.map { seg in
            "[\(seg.speaker)] \(seg.text)"
        }.joined(separator: "\n")

        // Step 3: Ask the LLM to identify real names
        let speakerMapping = try await GroqService.shared.identifySpeakersFromTranscript(
            labeledTranscript: labeledTranscript,
            speakerCount: heuristicResult.speakerCount
        )

        // Step 4: Apply the name mapping to segments
        let namedSegments = heuristicResult.segments.map { seg in
            let resolvedName = speakerMapping[seg.speaker] ?? seg.speaker
            return SpeakerSegment(
                id: seg.id,
                speaker: resolvedName,
                start: seg.start,
                end: seg.end,
                text: seg.text
            )
        }

        let uniqueSpeakers = Set(namedSegments.map { $0.speaker })
        return SpeakerIdentificationResult(segments: namedSegments, speakerCount: uniqueSpeakers.count)
    }

    // MARK: - Helpers

    private func speakerIndexFromLabel(_ label: String) -> Int {
        guard label.hasPrefix("Speaker "),
              let index = Int(label.dropFirst("Speaker ".count)) else {
            return 1
        }
        return index
    }

    /// Merges consecutive segments that share the same speaker into single segments.
    private func mergeConsecutiveSpeakerSegments(_ segments: [SpeakerSegment]) -> [SpeakerSegment] {
        guard !segments.isEmpty else { return [] }

        var merged: [SpeakerSegment] = []
        var current = segments[0]

        for i in 1..<segments.count {
            let next = segments[i]
            if next.speaker == current.speaker {
                // Merge: extend the current segment
                current = SpeakerSegment(
                    id: current.id,
                    speaker: current.speaker,
                    start: current.start,
                    end: next.end,
                    text: current.text + " " + next.text
                )
            } else {
                merged.append(current)
                current = next
            }
        }
        merged.append(current)

        return merged
    }
}
