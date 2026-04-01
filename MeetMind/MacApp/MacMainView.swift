#if os(macOS)
import SwiftUI

struct MacMainView: View {
    @EnvironmentObject var meetingService: MeetingService
    @StateObject private var todoService = TodoService.shared
    @StateObject private var appDetector = MeetingAppDetector.shared

    @State private var activeSection: MacSection = .meetings
    @State private var selectedMeetingId: UUID?
    @State private var isRecording = false

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            MacSidebar(
                activeSection: $activeSection,
                isRecording: isRecording,
                onStartRecording: { isRecording = true }
            )
            .environmentObject(meetingService)

            Divider()

            // Content area
            if isRecording {
                MacRecordingView(
                    appDetector: appDetector,
                    isRecording: $isRecording
                )
                .environmentObject(meetingService)
            } else {
                contentView
            }
        }
        .frame(minWidth: 1000, minHeight: 600)
        .onAppear {
            appDetector.startMonitoring()
        }
        .onDisappear {
            appDetector.stopMonitoring()
        }
        .onReceive(NotificationCenter.default.publisher(for: .macStartRecording)) { _ in
            isRecording = true
        }
        // Keyboard shortcuts
        .background(
            Group {
                // Cmd+N: New Recording
                Button("") { isRecording = true }
                    .keyboardShortcut("n", modifiers: .command)
                    .hidden()

                // Cmd+F: Search
                Button("") { activeSection = .search }
                    .keyboardShortcut("f", modifiers: .command)
                    .hidden()

                // Cmd+,: Settings
                Button("") { activeSection = .settings }
                    .keyboardShortcut(",", modifiers: .command)
                    .hidden()

                // Cmd+1-9: Section switching
                Button("") { activeSection = .meetings }
                    .keyboardShortcut("1", modifiers: .command)
                    .hidden()
                Button("") { activeSection = .todos }
                    .keyboardShortcut("2", modifiers: .command)
                    .hidden()
                Button("") { activeSection = .actionItems }
                    .keyboardShortcut("3", modifiers: .command)
                    .hidden()
                Button("") { activeSection = .notes }
                    .keyboardShortcut("4", modifiers: .command)
                    .hidden()
                Button("") { activeSection = .people }
                    .keyboardShortcut("5", modifiers: .command)
                    .hidden()
                Button("") { activeSection = .library }
                    .keyboardShortcut("6", modifiers: .command)
                    .hidden()
                Button("") { activeSection = .chat }
                    .keyboardShortcut("7", modifiers: .command)
                    .hidden()
                Button("") { activeSection = .recipes }
                    .keyboardShortcut("8", modifiers: .command)
                    .hidden()
            }
        )
    }

    // MARK: - Content Switching

    @ViewBuilder
    private var contentView: some View {
        switch activeSection {
        case .meetings:
            meetingsLayout
        case .todos:
            MacTodosView()
                .environmentObject(todoService)
        case .actionItems:
            MacActionItemsView()
                .environmentObject(meetingService)
        case .notes:
            MacNotesView()
                .environmentObject(meetingService)
        case .people:
            MacPeopleView()
                .environmentObject(meetingService)
        case .library:
            MacLibraryView()
                .environmentObject(meetingService)
        case .search:
            MacSearchView()
                .environmentObject(meetingService)
        case .chat:
            MacChatView()
                .environmentObject(meetingService)
                .environmentObject(todoService)
        case .recipes:
            MacRecipesView()
                .environmentObject(meetingService)
        case .settings:
            MacSettingsView()
        }
    }

    // MARK: - Meetings: List + Detail

    private var meetingsLayout: some View {
        HStack(spacing: 0) {
            MacMeetingListPanel(selectedMeetingId: $selectedMeetingId)
                .environmentObject(meetingService)

            Divider()

            if let meetingId = selectedMeetingId,
               let meeting = meetingService.meetings.first(where: { $0.id == meetingId }) {
                MacMeetingDetail(meeting: meeting)
                    .environmentObject(meetingService)
            } else {
                emptyDetailView
            }
        }
    }

    private var emptyDetailView: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 48))
                .foregroundColor(MMColors.textTertiary.opacity(0.5))
            Text("Select a meeting")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(MMColors.textSecondary)
            Text("Choose a meeting from the list to view details")
                .font(.system(size: 12))
                .foregroundColor(MMColors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MMColors.backgroundElevated)
    }
}
#endif
