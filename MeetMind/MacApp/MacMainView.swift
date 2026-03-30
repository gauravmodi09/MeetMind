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
            // Icon Rail
            MacIconRail(activeSection: $activeSection, isRecording: isRecording)

            // Content area
            if isRecording {
                MacRecordingView(
                    appDetector: appDetector,
                    isRecording: $isRecording
                )
                .environmentObject(meetingService)
            } else {
                switch activeSection {
                case .meetings:
                    meetingsLayout
                case .todos:
                    MacTodosView()
                        .environmentObject(todoService)
                case .notes:
                    MacNotesView()
                        .environmentObject(meetingService)
                case .library:
                    MacLibraryView()
                        .environmentObject(meetingService)
                case .chat:
                    MacChatView()
                        .environmentObject(meetingService)
                case .settings:
                    MacSettingsView()
                }
            }
        }
        .frame(minWidth: 700, minHeight: 450)
        .onAppear {
            appDetector.startMonitoring()
        }
        .onDisappear {
            appDetector.stopMonitoring()
        }
        .onReceive(NotificationCenter.default.publisher(for: .macStartRecording)) { _ in
            isRecording = true
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
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "waveform.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("Select a meeting")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            }
        }
    }
}
#endif
