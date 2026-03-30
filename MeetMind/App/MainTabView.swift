import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var todoService: TodoService
    @State private var selectedTab: Tab = .meetings

    enum Tab: String {
        case meetings, notes, todos, chat, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MeetingsView()
                .tabItem {
                    Image(systemName: "waveform.circle.fill")
                    Text("Meetings")
                }
                .tag(Tab.meetings)

            QuickNotesListView()
                .tabItem {
                    Image(systemName: "note.text")
                    Text("Notes")
                }
                .tag(Tab.notes)

            TodosView()
                .tabItem {
                    Image(systemName: "checklist")
                    Text("Todos")
                }
                .tag(Tab.todos)
                .badge(todoService.pendingCount > 0 ? todoService.pendingCount : 0)

            MeetingChatView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Chat")
                }
                .tag(Tab.chat)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(Tab.settings)
        }
        .tint(MMColors.primary)
        #if os(iOS)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        #endif
        .onReceive(NotificationCenter.default.publisher(for: .widgetStartRecording)) { _ in
            selectedTab = .meetings
            // Post to MeetingsView to auto-start recording
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: .autoStartRecording, object: nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .widgetAddTodo)) { _ in
            selectedTab = .todos
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: .autoShowTextTodo, object: nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .widgetVoiceTodo)) { _ in
            selectedTab = .todos
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: .autoStartVoiceTodo, object: nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .widgetShowTodos)) { _ in
            selectedTab = .todos
        }
        .onAppear {
            #if os(iOS)
            // Purple pill badge styling instead of default red
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
            appearance.backgroundColor = UIColor(white: 0.98, alpha: 0.9)
            appearance.shadowColor = UIColor(white: 0.0, alpha: 0.06)
            appearance.shadowImage = UIImage()

            // Badge appearance — purple pill
            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.normal.badgeBackgroundColor = UIColor(MMColors.primary)
            itemAppearance.normal.badgeTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 11, weight: .bold)
            ]
            itemAppearance.selected.badgeBackgroundColor = UIColor(MMColors.primary)
            itemAppearance.selected.badgeTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 11, weight: .bold)
            ]

            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            #endif
        }
    }
}

// MARK: - Placeholder Views (will be replaced with real feature views)

struct MeetingsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            MMEmptyState(
                icon: "mic.slash",
                title: "No meetings yet",
                message: "Tap the record button to capture your first meeting.",
                buttonTitle: "Record Meeting",
                buttonAction: {}
            )
            .background(MMColors.background)
            .navigationTitle("Meetings")
        }
    }
}

struct TodosPlaceholderView: View {
    var body: some View {
        NavigationStack {
            MMEmptyState(
                icon: "checklist",
                title: "All clear!",
                message: "No pending todos. Add one manually or let AI extract them from your meetings.",
                buttonTitle: "Add Todo",
                buttonAction: {}
            )
            .background(MMColors.background)
            .navigationTitle("Todos")
        }
    }
}

struct LibraryPlaceholderView: View {
    var body: some View {
        NavigationStack {
            MMEmptyState(
                icon: "folder",
                title: "Library is empty",
                message: "Your completed meeting briefs and transcripts will appear here."
            )
            .background(MMColors.background)
            .navigationTitle("Library")
        }
    }
}

// MARK: - Auto-Action Notifications

extension Notification.Name {
    static let autoStartRecording = Notification.Name("autoStartRecording")
    static let autoShowTextTodo = Notification.Name("autoShowTextTodo")
    static let autoStartVoiceTodo = Notification.Name("autoStartVoiceTodo")
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(MeetingService.shared)
        .environmentObject(TodoService.shared)
}
