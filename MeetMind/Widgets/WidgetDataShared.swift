import Foundation

/// Shared widget data model — used by both the main app and widget extension
/// Keep in sync with MeetMindWidgetExtension/MeetMindWidgets.swift
struct WidgetTodo: Codable, Identifiable {
    var id: String { title }
    let title: String
    let priority: String
    let dueDate: String
}

struct MeetMindWidgetData: Codable {
    let meetingCount: Int
    let lastMeetingTitle: String?
    let pendingTodoCount: Int
    let pendingTodos: [WidgetTodo]
    let updatedAt: Date

    static let placeholder = MeetMindWidgetData(
        meetingCount: 0,
        lastMeetingTitle: nil,
        pendingTodoCount: 0,
        pendingTodos: [],
        updatedAt: Date()
    )

    /// Save widget data to shared App Group container
    static func save(_ data: MeetMindWidgetData) {
        guard let defaults = UserDefaults(suiteName: "group.com.meetmind.shared"),
              let encoded = try? JSONEncoder().encode(data)
        else { return }
        defaults.set(encoded, forKey: "widgetData")
    }

    /// Load widget data from shared App Group container
    static func load() -> MeetMindWidgetData {
        guard let defaults = UserDefaults(suiteName: "group.com.meetmind.shared"),
              let data = defaults.data(forKey: "widgetData"),
              let decoded = try? JSONDecoder().decode(MeetMindWidgetData.self, from: data)
        else { return .placeholder }
        return decoded
    }
}
