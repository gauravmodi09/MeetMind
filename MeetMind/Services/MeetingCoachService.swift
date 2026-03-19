import Foundation

// MARK: - Meeting Coach Report

struct SpeakerCoachMetrics: Identifiable {
    let id = UUID()
    let speaker: String
    let fillerWordCount: Int
    let fillerBreakdown: [String: Int]
    let talkRatioPercent: Double
    let wordsPerMinute: Double
    let longestMonologueSeconds: Double
    let questionCount: Int
    let interruptionCount: Int
    let totalSpeakingSeconds: Double
    let totalWords: Int
}

struct MeetingCoachReport {
    let meetingDuration: TimeInterval
    let speakerMetrics: [SpeakerCoachMetrics]
    let totalFillerWords: Int
    let totalQuestions: Int
    let totalInterruptions: Int
    let generatedAt: Date

    // MARK: - Convenience

    var primarySpeaker: SpeakerCoachMetrics? {
        speakerMetrics.max(by: { $0.talkRatioPercent < $1.talkRatioPercent })
    }
}

// MARK: - Meeting Coach Service

@MainActor
final class MeetingCoachService {
    static let shared = MeetingCoachService()

    private init() {}

    // MARK: - Filler Words

    private let fillerWords: [String] = [
        "um", "uh", "like", "you know", "basically",
        "actually", "so", "right", "i mean"
    ]

    // MARK: - Analyze

    func analyze(segments: [TranscriptSegment], speakerMap: [Int: String]? = nil) -> MeetingCoachReport {
        // Group segments by speaker label
        let labeled = labelSegments(segments, speakerMap: speakerMap)
        let speakers = Set(labeled.map { $0.speaker })
        let sorted = labeled.sorted(by: { $0.start < $1.start })

        let meetingDuration: TimeInterval = {
            guard let first = sorted.first, let last = sorted.last else { return 0 }
            return last.end - first.start
        }()

        var allMetrics: [SpeakerCoachMetrics] = []
        var totalFillers = 0
        var totalQuestions = 0
        var totalInterruptions = 0

        for speaker in speakers {
            let speakerSegments = sorted.filter { $0.speaker == speaker }

            // Filler words
            let (fillerCount, fillerBreakdown) = countFillers(in: speakerSegments)
            totalFillers += fillerCount

            // Talk ratio
            let totalSpeaking = speakerSegments.reduce(0.0) { $0 + ($1.end - $1.start) }
            let talkRatio = meetingDuration > 0 ? (totalSpeaking / meetingDuration) * 100.0 : 0

            // Word count & pace
            let totalWords = speakerSegments.reduce(0) { $0 + wordCount($1.text) }
            let speakingMinutes = totalSpeaking / 60.0
            let wpm = speakingMinutes > 0 ? Double(totalWords) / speakingMinutes : 0

            // Longest monologue
            let longestMonologue = longestContinuousStretch(for: speaker, in: sorted)

            // Questions
            let questions = speakerSegments.reduce(0) { $0 + questionCount($1.text) }
            totalQuestions += questions

            // Interruptions
            let interruptions = countInterruptions(for: speaker, in: sorted)
            totalInterruptions += interruptions

            allMetrics.append(SpeakerCoachMetrics(
                speaker: speaker,
                fillerWordCount: fillerCount,
                fillerBreakdown: fillerBreakdown,
                talkRatioPercent: talkRatio,
                wordsPerMinute: wpm,
                longestMonologueSeconds: longestMonologue,
                questionCount: questions,
                interruptionCount: interruptions,
                totalSpeakingSeconds: totalSpeaking,
                totalWords: totalWords
            ))
        }

        // Sort by talk ratio descending
        allMetrics.sort { $0.talkRatioPercent > $1.talkRatioPercent }

        return MeetingCoachReport(
            meetingDuration: meetingDuration,
            speakerMetrics: allMetrics,
            totalFillerWords: totalFillers,
            totalQuestions: totalQuestions,
            totalInterruptions: totalInterruptions,
            generatedAt: Date()
        )
    }

    // MARK: - Private Helpers

    private struct LabeledSegment {
        let speaker: String
        let start: Double
        let end: Double
        let text: String
    }

    private func labelSegments(_ segments: [TranscriptSegment], speakerMap: [Int: String]?) -> [LabeledSegment] {
        // If no speaker map, treat everything as "You" (single speaker)
        // We try to split by speaker labels in the text like "Speaker 1:" patterns
        var result: [LabeledSegment] = []

        for (index, seg) in segments.enumerated() {
            let speaker: String
            if let map = speakerMap, let name = map[index] {
                speaker = name
            } else {
                // Try to detect speaker label from text prefix
                speaker = extractSpeakerLabel(from: seg.text) ?? "Speaker 1"
            }

            let cleanText = removeSpeakerPrefix(from: seg.text)
            result.append(LabeledSegment(
                speaker: speaker,
                start: seg.start,
                end: seg.end,
                text: cleanText
            ))
        }

        return result
    }

    private func extractSpeakerLabel(from text: String) -> String? {
        // Match patterns like "Speaker 1:", "John:", etc.
        let pattern = #"^(Speaker \d+|[A-Z][a-zA-Z]+)\s*:"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[range])
    }

    private func removeSpeakerPrefix(from text: String) -> String {
        let pattern = #"^(Speaker \d+|[A-Z][a-zA-Z]+)\s*:\s*"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
    }

    private func countFillers(in segments: [LabeledSegment]) -> (Int, [String: Int]) {
        var total = 0
        var breakdown: [String: Int] = [:]

        for segment in segments {
            let lower = segment.text.lowercased()
            for filler in fillerWords {
                let count = countOccurrences(of: filler, in: lower)
                if count > 0 {
                    total += count
                    breakdown[filler, default: 0] += count
                }
            }
        }

        return (total, breakdown)
    }

    private func countOccurrences(of word: String, in text: String) -> Int {
        // Use word boundary matching so "like" doesn't match "likely"
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return 0 }
        return regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
    }

    private func wordCount(_ text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace }).count
    }

    private func questionCount(_ text: String) -> Int {
        text.components(separatedBy: "?").count - 1
    }

    private func longestContinuousStretch(for speaker: String, in sorted: [LabeledSegment]) -> Double {
        var longest: Double = 0
        var currentStretch: Double = 0
        var stretchStart: Double?

        for seg in sorted {
            if seg.speaker == speaker {
                if stretchStart == nil {
                    stretchStart = seg.start
                }
                currentStretch = seg.end - (stretchStart ?? seg.start)
            } else {
                if currentStretch > longest {
                    longest = currentStretch
                }
                currentStretch = 0
                stretchStart = nil
            }
        }

        // Check final stretch
        if currentStretch > longest {
            longest = currentStretch
        }

        return longest
    }

    private func countInterruptions(for speaker: String, in sorted: [LabeledSegment]) -> Int {
        var count = 0

        for i in 1..<sorted.count {
            let current = sorted[i]
            let previous = sorted[i - 1]

            // An interruption: this speaker starts before the previous speaker ended
            if current.speaker == speaker && previous.speaker != speaker {
                if current.start < previous.end {
                    count += 1
                }
            }
        }

        return count
    }

    // MARK: - Coaching Tips

    static func tips(for metrics: SpeakerCoachMetrics, meetingDuration: TimeInterval) -> [CoachingTip] {
        var tips: [CoachingTip] = []

        // Filler word tips
        let fillerRate = metrics.totalSpeakingSeconds > 0
            ? Double(metrics.fillerWordCount) / (metrics.totalSpeakingSeconds / 60.0)
            : 0
        if fillerRate > 5 {
            tips.append(CoachingTip(
                category: .fillerWords,
                severity: .needsWork,
                message: "You used \(metrics.fillerWordCount) filler words (\(String(format: "%.0f", fillerRate))/min). Try pausing silently instead."
            ))
        } else if fillerRate > 2 {
            tips.append(CoachingTip(
                category: .fillerWords,
                severity: .okay,
                message: "Moderate filler word usage (\(String(format: "%.0f", fillerRate))/min). You're aware — keep practicing pauses."
            ))
        } else {
            tips.append(CoachingTip(
                category: .fillerWords,
                severity: .good,
                message: "Minimal filler words. Clean and confident delivery."
            ))
        }

        // Speaking pace tips
        if metrics.wordsPerMinute > 180 {
            tips.append(CoachingTip(
                category: .speakingPace,
                severity: .needsWork,
                message: "Speaking at \(Int(metrics.wordsPerMinute)) WPM — too fast. Aim for 130-160 WPM for clarity."
            ))
        } else if metrics.wordsPerMinute < 100 && metrics.wordsPerMinute > 0 {
            tips.append(CoachingTip(
                category: .speakingPace,
                severity: .okay,
                message: "Speaking at \(Int(metrics.wordsPerMinute)) WPM — a bit slow. Pick up the pace to keep engagement."
            ))
        } else if metrics.wordsPerMinute > 0 {
            tips.append(CoachingTip(
                category: .speakingPace,
                severity: .good,
                message: "Great pace at \(Int(metrics.wordsPerMinute)) WPM. Clear and easy to follow."
            ))
        }

        // Talk ratio tips
        if metrics.talkRatioPercent > 70 {
            tips.append(CoachingTip(
                category: .talkRatio,
                severity: .needsWork,
                message: "You spoke \(Int(metrics.talkRatioPercent))% of the time. Leave more room for others."
            ))
        } else if metrics.talkRatioPercent < 20 && meetingDuration > 120 {
            tips.append(CoachingTip(
                category: .talkRatio,
                severity: .okay,
                message: "Only \(Int(metrics.talkRatioPercent))% talk time. Consider contributing more to the discussion."
            ))
        } else {
            tips.append(CoachingTip(
                category: .talkRatio,
                severity: .good,
                message: "Balanced talk ratio at \(Int(metrics.talkRatioPercent))%. Good conversational balance."
            ))
        }

        // Monologue tips
        if metrics.longestMonologueSeconds > 180 {
            tips.append(CoachingTip(
                category: .monologue,
                severity: .needsWork,
                message: "Longest monologue was \(formatDuration(metrics.longestMonologueSeconds)). Break up long stretches with check-ins."
            ))
        } else if metrics.longestMonologueSeconds > 90 {
            tips.append(CoachingTip(
                category: .monologue,
                severity: .okay,
                message: "Longest monologue was \(formatDuration(metrics.longestMonologueSeconds)). Try to keep turns under 90 seconds."
            ))
        }

        // Interruptions
        if metrics.interruptionCount > 3 {
            tips.append(CoachingTip(
                category: .interruptions,
                severity: .needsWork,
                message: "You interrupted \(metrics.interruptionCount) times. Practice active listening before responding."
            ))
        } else if metrics.interruptionCount > 0 {
            tips.append(CoachingTip(
                category: .interruptions,
                severity: .okay,
                message: "\(metrics.interruptionCount) potential interruption(s) detected. Stay mindful of others finishing."
            ))
        }

        // Questions
        if metrics.questionCount == 0 && meetingDuration > 120 {
            tips.append(CoachingTip(
                category: .questions,
                severity: .okay,
                message: "No questions asked. Asking questions shows engagement and curiosity."
            ))
        } else if metrics.questionCount >= 3 {
            tips.append(CoachingTip(
                category: .questions,
                severity: .good,
                message: "Asked \(metrics.questionCount) questions — great engagement and curiosity."
            ))
        }

        return tips
    }

    private static func formatDuration(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if mins > 0 {
            return "\(mins)m \(secs)s"
        }
        return "\(secs)s"
    }
}

// MARK: - Coaching Tip

struct CoachingTip: Identifiable {
    let id = UUID()
    let category: CoachingCategory
    let severity: CoachingSeverity
    let message: String
}

enum CoachingCategory: String {
    case fillerWords = "Filler Words"
    case speakingPace = "Speaking Pace"
    case talkRatio = "Talk Ratio"
    case monologue = "Monologue"
    case interruptions = "Interruptions"
    case questions = "Questions"

    var icon: String {
        switch self {
        case .fillerWords:   return "text.bubble"
        case .speakingPace:  return "speedometer"
        case .talkRatio:     return "chart.pie"
        case .monologue:     return "person.wave.2"
        case .interruptions: return "hand.raised"
        case .questions:     return "questionmark.bubble"
        }
    }
}

enum CoachingSeverity {
    case good
    case okay
    case needsWork
}
