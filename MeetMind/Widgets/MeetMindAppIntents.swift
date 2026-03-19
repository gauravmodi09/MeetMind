import AppIntents
import Foundation

// MARK: - Start Recording Intent

struct StartRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Recording"
    static var description: IntentDescription = IntentDescription("Start a new MeetMind recording session.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .startRecordingFromWidget, object: nil)
        return .result()
    }
}

// MARK: - Add Todo Intent

struct AddTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Todo"
    static var description: IntentDescription = IntentDescription("Open MeetMind to add a new todo item.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .addTodoFromWidget, object: nil)
        return .result()
    }
}

// MARK: - Widget Notification Names

extension Notification.Name {
    static let startRecordingFromWidget = Notification.Name("startRecordingFromWidget")
    static let addTodoFromWidget = Notification.Name("addTodoFromWidget")
}

// MARK: - App Shortcuts Provider

struct MeetMindShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartRecordingIntent(),
            phrases: [
                "Start recording in \(.applicationName)",
                "Record a meeting with \(.applicationName)",
                "Start \(.applicationName) recording"
            ],
            shortTitle: "Start Recording",
            systemImageName: "mic.fill"
        )
        AppShortcut(
            intent: AddTodoIntent(),
            phrases: [
                "Add a todo in \(.applicationName)",
                "Create a task in \(.applicationName)"
            ],
            shortTitle: "Add Todo",
            systemImageName: "plus.circle.fill"
        )
    }
}
