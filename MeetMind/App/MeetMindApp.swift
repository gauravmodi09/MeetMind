import SwiftUI

@main
struct MeetMindApp: App {
    let persistence = PersistenceController.shared
    @AppStorage("hasCompletedOnboarding") var hasOnboarded = false
    @AppStorage("groqAPIKey") var apiKey = ""

    init() {
        // Auto-load API key from Secrets.plist if not set
        if apiKey.isEmpty {
            if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path),
               let key = dict["GROQ_API_KEY"] as? String,
               !key.isEmpty {
                apiKey = key
                KeychainService.save(key: key)
            }
        }

        BackgroundTaskService.shared.registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                MainTabView()
                    .environment(\.managedObjectContext, persistence.container.viewContext)
                    .environmentObject(MeetingService.shared)
                    .environmentObject(TodoService.shared)
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
            } else {
                OnboardingView()
                    .environment(\.managedObjectContext, persistence.container.viewContext)
                    .environmentObject(MeetingService.shared)
                    .environmentObject(TodoService.shared)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let host = url.host else { return }
        switch host {
        case "record":
            NotificationCenter.default.post(name: .widgetStartRecording, object: nil)
        case "add-todo":
            NotificationCenter.default.post(name: .widgetAddTodo, object: nil)
        case "voice-todo":
            NotificationCenter.default.post(name: .widgetVoiceTodo, object: nil)
        case "todos":
            NotificationCenter.default.post(name: .widgetShowTodos, object: nil)
        default:
            break
        }
    }
}

// MARK: - Deep Link Notification Names

extension Notification.Name {
    static let widgetStartRecording = Notification.Name("widgetStartRecording")
    static let widgetAddTodo = Notification.Name("widgetAddTodo")
    static let widgetVoiceTodo = Notification.Name("widgetVoiceTodo")
    static let widgetShowTodos = Notification.Name("widgetShowTodos")
}
