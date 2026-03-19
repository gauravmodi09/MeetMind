import Foundation

// MARK: - Meeting Prep Context

struct MeetingPrepContext {
    let lastMeetingTitle: String?
    let lastMeetingDate: Date?
    let pendingActionItems: [ActionItem]
    let unresolvedBlockers: [String]
    let hasContext: Bool

    static let empty = MeetingPrepContext(
        lastMeetingTitle: nil,
        lastMeetingDate: nil,
        pendingActionItems: [],
        unresolvedBlockers: [],
        hasContext: false
    )
}

// MARK: - Meeting Prep Service

@MainActor
class MeetingPrepService {
    static let shared = MeetingPrepService()
    private init() {}

    /// Builds a prep context for the given client by querying MeetingService history.
    func prepareContext(for client: String?) -> MeetingPrepContext {
        guard let client, !client.isEmpty else {
            return .empty
        }

        let allMeetings = MeetingService.shared.meetings
        let clientMeetings = allMeetings
            .filter { $0.clientName == client && $0.status == .complete }
            .sorted { $0.date > $1.date }

        guard let lastMeeting = clientMeetings.first else {
            return .empty
        }

        // Collect incomplete action items across all client meetings (most recent first)
        let pendingItems = clientMeetings.flatMap { meeting in
            meeting.briefActionItems.filter { !$0.isCompleted }
        }

        // Extract blockers from the last meeting's summary
        let blockers = extractBlockers(from: lastMeeting.briefSummary)

        return MeetingPrepContext(
            lastMeetingTitle: lastMeeting.title,
            lastMeetingDate: lastMeeting.date,
            pendingActionItems: pendingItems,
            unresolvedBlockers: blockers,
            hasContext: true
        )
    }

    // MARK: - Private

    /// Parses the BLOCKERS section from a meeting summary markdown string.
    private func extractBlockers(from summary: String?) -> [String] {
        guard let summary, !summary.isEmpty else { return [] }

        var blockers: [String] = []
        var inBlockerSection = false

        for line in summary.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.uppercased().contains("BLOCKERS") || trimmed.uppercased().contains("OPEN QUESTIONS") {
                inBlockerSection = true
                continue
            }

            // A new section header ends the blocker section
            if inBlockerSection && (trimmed.hasPrefix("#") || (trimmed.uppercased() == trimmed && trimmed.count > 3 && !trimmed.hasPrefix("-"))) {
                if !trimmed.isEmpty && !trimmed.hasPrefix("-") {
                    inBlockerSection = false
                    continue
                }
            }

            if inBlockerSection && trimmed.hasPrefix("- ") {
                let text = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                if !text.isEmpty {
                    blockers.append(text)
                }
            }
        }

        return blockers
    }
}
