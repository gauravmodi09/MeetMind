#if os(macOS)
import SwiftUI

struct MacMainView: View {
    @EnvironmentObject var meetingService: MeetingService
    @State private var selectedSidebar: SidebarItem = .meetings
    @State private var selectedMeetingId: UUID?

    enum SidebarItem: String, CaseIterable, Hashable {
        case meetings = "Meetings"
        case todos = "Todos"
        case library = "Library"

        var icon: String {
            switch self {
            case .meetings: return "waveform.circle.fill"
            case .todos: return "checklist"
            case .library: return "folder.fill"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SidebarItem.allCases, id: \.self, selection: $selectedSidebar) { item in
                Label(item.rawValue, systemImage: item.icon)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .listStyle(.sidebar)
        } content: {
            // Meeting list
            List(meetingService.meetings, selection: $selectedMeetingId) { meeting in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meeting.title)
                            .font(.headline)
                        Text(meeting.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if meeting.status == .complete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                .tag(meeting.id)
                .padding(.vertical, 4)
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 300)
        } detail: {
            // Detail view
            if let meetingId = selectedMeetingId,
               let meeting = meetingService.meetings.first(where: { $0.id == meetingId }) {
                MacMeetingDetailView(meeting: meeting)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "waveform.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Select a meeting")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}

struct MacMeetingDetailView: View {
    let meeting: Meeting

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text(meeting.title)
                    .font(.largeTitle.bold())

                // Metadata
                HStack(spacing: 16) {
                    Label(meeting.date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    Label(formatDuration(meeting.duration), systemImage: "clock")
                    if let client = meeting.clientName {
                        Label(client, systemImage: "person.fill")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                Divider()

                // Summary
                if let summary = meeting.briefSummary {
                    Text(summary)
                        .textSelection(.enabled)
                }

                // Action items
                if !meeting.briefActionItems.isEmpty {
                    Text("Action Items")
                        .font(.title2.bold())
                        .padding(.top, 8)

                    ForEach(meeting.briefActionItems) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(item.isCompleted ? .green : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.text)
                                if !item.owner.isEmpty {
                                    Text(item.owner)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}
#endif
