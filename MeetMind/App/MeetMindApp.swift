import SwiftUI
import FirebaseCore

@main
struct MeetMindApp: App {
    let persistence: PersistenceController = {
        if UserDefaults.standard.bool(forKey: "iCloudSyncEnabled") {
            return PersistenceController.cloudKitController() ?? PersistenceController.shared
        }
        return PersistenceController.shared
    }()

    @StateObject private var authService = AuthService.shared
    @AppStorage("hasCompletedOnboarding") var hasOnboarded = false
    @AppStorage("groqAPIKey") var apiKey = ""
    @AppStorage("appTheme") var appTheme = "system"

    var colorSchemeFromSetting: ColorScheme? {
        switch appTheme {
        case "dark": return .dark
        case "light": return .light
        default: return nil
        }
    }

    init() {
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
            Group {
                if authService.isLoading {
                    splashView
                } else if !authService.isSignedIn {
                    SignInView()
                        .environmentObject(authService)
                } else if !hasOnboarded {
                    ProfileSetupView()
                        .environmentObject(authService)
                } else {
                    MainTabView()
                        .environment(\.managedObjectContext, persistence.container.viewContext)
                        .environmentObject(MeetingService.shared)
                        .environmentObject(TodoService.shared)
                        .environmentObject(authService)
                        .onOpenURL { url in
                            handleDeepLink(url)
                        }
                }
            }
            .preferredColorScheme(colorSchemeFromSetting)
        }
    }

    private var splashView: some View {
        ZStack {
            MMColors.background.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(MMColors.primary)
                ProgressView()
                    .tint(MMColors.primary)
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

extension Notification.Name {
    static let widgetStartRecording = Notification.Name("widgetStartRecording")
    static let widgetAddTodo = Notification.Name("widgetAddTodo")
    static let widgetVoiceTodo = Notification.Name("widgetVoiceTodo")
    static let widgetShowTodos = Notification.Name("widgetShowTodos")
}
