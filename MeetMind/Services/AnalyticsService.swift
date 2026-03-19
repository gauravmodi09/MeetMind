import Foundation

// MARK: - Analytics Event

enum AnalyticsEvent: String, CaseIterable {
    case recordingStarted = "record_start"
    case recordingStopped = "record_stop"
    case transcriptionComplete = "transcribe_complete"
    case briefCopied = "brief_copied"
    case briefShared = "brief_shared"
    case todoCreated = "todo_created"
    case todoCompleted = "todo_completed"
    case voiceTodoCreated = "voice_todo_created"
    case meetingViewed = "meeting_viewed"
    case searchPerformed = "search_performed"

    var displayName: String {
        switch self {
        case .recordingStarted:       return "Recordings Started"
        case .recordingStopped:        return "Recordings Stopped"
        case .transcriptionComplete:   return "Transcriptions Completed"
        case .briefCopied:             return "Briefs Copied"
        case .briefShared:             return "Briefs Shared"
        case .todoCreated:             return "Todos Created"
        case .todoCompleted:           return "Todos Completed"
        case .voiceTodoCreated:        return "Voice Todos Created"
        case .meetingViewed:           return "Meetings Viewed"
        case .searchPerformed:         return "Searches Performed"
        }
    }
}

// MARK: - Analytics Service

@MainActor
class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()

    private let storagePrefix = "analytics_"

    private init() {}

    // MARK: - Track

    /// Increments the counter for the given event.
    func track(_ event: AnalyticsEvent) {
        let key = storagePrefix + event.rawValue
        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(current + 1, forKey: key)
        objectWillChange.send()
    }

    // MARK: - Query

    /// Returns the total count for a specific event.
    func getEventCount(_ event: AnalyticsEvent) -> Int {
        let key = storagePrefix + event.rawValue
        return UserDefaults.standard.integer(forKey: key)
    }

    /// Returns a dictionary of all event raw values to their counts.
    func getAllStats() -> [String: Int] {
        var stats: [String: Int] = [:]
        for event in AnalyticsEvent.allCases {
            let count = getEventCount(event)
            if count > 0 {
                stats[event.rawValue] = count
            }
        }
        return stats
    }

    /// Returns all events with their counts, including zeros.
    func getAllEventCounts() -> [(event: AnalyticsEvent, count: Int)] {
        AnalyticsEvent.allCases.map { ($0, getEventCount($0)) }
    }

    // MARK: - Reset

    /// Clears all analytics data.
    func resetAll() {
        for event in AnalyticsEvent.allCases {
            let key = storagePrefix + event.rawValue
            UserDefaults.standard.removeObject(forKey: key)
        }
        objectWillChange.send()
    }
}
