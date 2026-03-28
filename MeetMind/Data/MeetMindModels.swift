import Foundation

// MARK: - Meeting

struct Meeting: Identifiable {
    let id: UUID
    var title: String
    var date: Date
    var duration: TimeInterval
    var audioFilePath: String?
    var clientName: String?
    var status: MeetingStatus
    var template: MeetingTemplate
    var briefSummary: String?
    var briefDecisions: [String]
    var briefActionItems: [ActionItem]
    var briefKeyTopics: [String]
    var briefKeyQuotes: [String]
    var rawTranscript: String?
    var userNotes: String?
    var notepadContent: String?
    var enhancedNotes: [EnhancedBlock]?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        date: Date = Date(),
        duration: TimeInterval = 0,
        audioFilePath: String? = nil,
        clientName: String? = nil,
        status: MeetingStatus = .recording,
        template: MeetingTemplate = .general,
        briefSummary: String? = nil,
        briefDecisions: [String] = [],
        briefActionItems: [ActionItem] = [],
        briefKeyTopics: [String] = [],
        briefKeyQuotes: [String] = [],
        rawTranscript: String? = nil,
        userNotes: String? = nil,
        notepadContent: String? = nil,
        enhancedNotes: [EnhancedBlock]? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.audioFilePath = audioFilePath
        self.clientName = clientName
        self.status = status
        self.template = template
        self.briefSummary = briefSummary
        self.briefDecisions = briefDecisions
        self.briefActionItems = briefActionItems
        self.briefKeyTopics = briefKeyTopics
        self.briefKeyQuotes = briefKeyQuotes
        self.rawTranscript = rawTranscript
        self.userNotes = userNotes
        self.notepadContent = notepadContent
        self.enhancedNotes = enhancedNotes
        self.createdAt = createdAt
    }
}

// MARK: - EnhancedBlock

struct EnhancedBlock: Codable, Identifiable {
    let id: UUID
    let text: String
    let isAI: Bool
    let citationRange: String?
    let citationText: String?

    init(
        id: UUID = UUID(),
        text: String,
        isAI: Bool,
        citationRange: String? = nil,
        citationText: String? = nil
    ) {
        self.id = id
        self.text = text
        self.isAI = isAI
        self.citationRange = citationRange
        self.citationText = citationText
    }
}

// MARK: - ActionItem

struct ActionItem: Codable, Identifiable {
    let id: UUID
    var text: String
    var owner: String
    var dueDate: Date?
    var isMine: Bool
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        text: String,
        owner: String = "",
        dueDate: Date? = nil,
        isMine: Bool = false,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.text = text
        self.owner = owner
        self.dueDate = dueDate
        self.isMine = isMine
        self.isCompleted = isCompleted
    }
}

// MARK: - TodoItem

struct TodoItem: Identifiable {
    let id: UUID
    var title: String
    var dueDate: Date
    var priority: TodoPriority
    var clientTag: String?
    var source: TodoSource
    var sourceMeetingId: UUID?
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date
    var recurrence: TodoRecurrence?

    init(
        id: UUID = UUID(),
        title: String,
        dueDate: Date = Date(),
        priority: TodoPriority = .medium,
        clientTag: String? = nil,
        source: TodoSource = .manual,
        sourceMeetingId: UUID? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        createdAt: Date = Date(),
        recurrence: TodoRecurrence? = nil
    ) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.priority = priority
        self.clientTag = clientTag
        self.source = source
        self.sourceMeetingId = sourceMeetingId
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.recurrence = recurrence
    }
}

// MARK: - Todo Recurrence

enum TodoRecurrence: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekdays = "Weekdays"
    case weekly = "Weekly"
    case monthly = "Monthly"

    /// Calculate the next due date from the given date based on recurrence type.
    func nextDueDate(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekdays:
            var next = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            while calendar.isDateInWeekend(next) {
                next = calendar.date(byAdding: .day, value: 1, to: next) ?? next
            }
            return next
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        }
    }
}

// MARK: - Client

struct Client: Identifiable {
    let id: UUID
    var name: String
    var color: String
    var meetingCount: Int
    var lastMeetingDate: Date?

    init(
        id: UUID = UUID(),
        name: String,
        color: String = "6C5CE7",
        meetingCount: Int = 0,
        lastMeetingDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.meetingCount = meetingCount
        self.lastMeetingDate = lastMeetingDate
    }
}

// MARK: - Meeting Recipe

struct MeetingRecipe: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String  // SF Symbol
    var prompt: String
    var isBuiltIn: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        prompt: String,
        isBuiltIn: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.prompt = prompt
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
    }

    static let builtIn: [MeetingRecipe] = [
        MeetingRecipe(
            name: "Coach me",
            icon: "figure.mind.and.body",
            prompt: "Analyze the communication style of the first speaker (the user) in this meeting transcript. Provide specific, actionable feedback on: clarity of communication, active listening indicators, persuasiveness, areas for improvement, and things done well. Be constructive and specific with examples from the transcript.",
            isBuiltIn: true
        ),
        MeetingRecipe(
            name: "Prep me",
            icon: "brain.head.profile",
            prompt: "Based on the context from past meetings provided, prepare a briefing for an upcoming call. Include: key topics previously discussed, outstanding action items, relationship context, potential discussion points, and any unresolved issues to follow up on.",
            isBuiltIn: true
        ),
        MeetingRecipe(
            name: "Write a brief",
            icon: "doc.text",
            prompt: "Create a professional document/brief from this brainstorm or strategy discussion. Structure it with: executive summary, key ideas discussed, strategic recommendations, next steps, and any decisions made. Format it so it can be shared with stakeholders.",
            isBuiltIn: true
        ),
        MeetingRecipe(
            name: "List objections",
            icon: "hand.raised",
            prompt: "Extract ALL objections, concerns, hesitations, and pushback raised during this meeting. For each objection, include: who raised it, the exact concern, any response given, and whether it was resolved. This is useful for sales follow-up.",
            isBuiltIn: true
        ),
        MeetingRecipe(
            name: "Extract questions",
            icon: "questionmark.bubble",
            prompt: "List ALL questions asked during this meeting. For each question, include: who asked it, the full question, whether it was answered, and the answer if provided. Group by topic if possible.",
            isBuiltIn: true
        ),
        MeetingRecipe(
            name: "Write follow-up email",
            icon: "envelope",
            prompt: "Generate a professional follow-up email based on this meeting. Include: a thank you, summary of key discussion points, agreed-upon action items with owners, next steps and timeline, and a professional closing. Keep the tone warm but professional.",
            isBuiltIn: true
        ),
    ]
}

// MARK: - Detected Participant

struct DetectedParticipant: Codable, Identifiable {
    var id: String { name }
    let name: String
    let company: String?
    let role: String?
}

// MARK: - Chat Message

struct ChatMessage: Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    var sourceMeetings: [String]

    init(
        id: UUID = UUID(),
        content: String,
        isUser: Bool,
        timestamp: Date = Date(),
        sourceMeetings: [String] = []
    ) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.sourceMeetings = sourceMeetings
    }
}

// MARK: - Enums

enum MeetingStatus: String, Codable, CaseIterable {
    case recording
    case processing
    case complete
    case failed

    var displayName: String {
        switch self {
        case .recording:  return "Recording"
        case .processing: return "Processing"
        case .complete:   return "Complete"
        case .failed:     return "Failed"
        }
    }
}

enum TodoPriority: String, Codable, CaseIterable {
    case low
    case medium
    case high

    var displayName: String { rawValue.capitalized }

    var sortOrder: Int {
        switch self {
        case .high:   return 0
        case .medium: return 1
        case .low:    return 2
        }
    }
}

enum TodoSource: String, Codable {
    case manual
    case voice
    case meeting

    var displayName: String { rawValue.capitalized }
}

// MARK: - Recording Quality

enum RecordingQuality: String, CaseIterable, Identifiable {
    case standard = "Standard (16 kHz)"
    case high = "High (44.1 kHz)"

    var id: String { rawValue }

    var sampleRate: Double {
        switch self {
        case .standard: return 16_000
        case .high:     return 44_100
        }
    }
}

// MARK: - Meeting Template

enum MeetingTemplate: String, Codable, CaseIterable {
    case general = "General"
    case oneOnOne = "1:1"
    case salesCall = "Sales Call"
    case interview = "Interview"
    case standup = "Standup"
    case discovery = "Discovery"
    case brainstorm = "Brainstorm"

    var icon: String {
        switch self {
        case .general:    return "person.3"
        case .oneOnOne:   return "person.2"
        case .salesCall:  return "dollarsign.circle"
        case .interview:  return "person.badge.clock"
        case .standup:    return "figure.stand"
        case .discovery:  return "magnifyingglass.circle"
        case .brainstorm: return "lightbulb"
        }
    }

    var promptModifier: String {
        switch self {
        case .general:
            return ""
        case .oneOnOne:
            return """
            This is a 1:1 meeting. Focus on personal goals, feedback exchanged, career development topics, \
            relationship-building moments, and any coaching or mentoring discussed. Highlight personal commitments \
            and growth areas.
            """
        case .salesCall:
            return """
            This is a sales call. Extract objections raised by the prospect, any budget mentions or pricing \
            discussions, timeline expectations, decision makers identified, next steps in the sales process, \
            and competitive mentions. Classify the deal stage if possible.
            """
        case .interview:
            return """
            This is an interview. Provide a candidate assessment including strengths demonstrated, concerns or \
            red flags, culture fit observations, technical competency evaluation, and a hire/no-hire recommendation \
            with reasoning.
            """
        case .standup:
            return """
            This is a standup meeting. Keep the summary very short and structured. For each participant, extract: \
            what they accomplished yesterday, any blockers they mentioned, and their plan for today. Be concise.
            """
        case .discovery:
            return """
            This is a discovery call. Focus on pain points expressed by the prospect, their current solution and \
            what they dislike about it, requirements and must-haves, budget range if mentioned, decision-making \
            process, and timeline for a decision.
            """
        case .brainstorm:
            return """
            This is a brainstorm session. Capture all ideas generated (even rough ones), group them by theme, \
            note which ideas got the most energy or agreement, any ideas that were ruled out and why, and the \
            final shortlist or decisions on next steps.
            """
        }
    }
}

// MARK: - AI Prompt Style

enum AIPromptStyle: String, CaseIterable, Identifiable {
    case concise = "Concise"
    case detailed = "Detailed"
    case executive = "Executive"

    var id: String { rawValue }
}

// MARK: - Auto-Delete Option

enum AudioRetention: String, CaseIterable, Identifiable {
    case sevenDays = "7 days"
    case fourteenDays = "14 days"
    case thirtyDays = "30 days"
    case never = "Never"

    var id: String { rawValue }

    var days: Int? {
        switch self {
        case .sevenDays:    return 7
        case .fourteenDays: return 14
        case .thirtyDays:   return 30
        case .never:        return nil
        }
    }
}
