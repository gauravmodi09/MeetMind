#if os(macOS)
import SwiftUI

struct MacMeetingListPanel: View {
    @EnvironmentObject var meetingService: MeetingService
    @Binding var selectedMeetingId: UUID?
    @State private var searchText = ""
    @State private var hoveredMeetingId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center) {
                Text("Meetings")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(MMColors.textPrimary)
                Spacer()
                Text("\(meetingService.meetings.count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MMColors.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(MMColors.background))
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(MMColors.textTertiary)
                TextField("Search meetings...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(MMColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(MMColors.background)
            )
            .padding(.horizontal, 14)
            .padding(.bottom, 14)

            Divider()
                .padding(.horizontal, 14)

            // Meeting list
            if filteredMeetings.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(groupedMeetings, id: \.key) { group in
                            Text(group.key)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(MMColors.textTertiary)
                                .textCase(.uppercase)
                                .tracking(0.6)
                                .padding(.horizontal, 18)
                                .padding(.top, 14)
                                .padding(.bottom, 6)

                            ForEach(group.meetings) { meeting in
                                meetingRow(meeting)
                                    .padding(.horizontal, 14)
                                    .padding(.bottom, 2)
                            }
                        }
                    }
                    .padding(.bottom, 14)
                }
            }
        }
        .frame(width: 260)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Meeting Row

    private func meetingRow(_ meeting: Meeting) -> some View {
        let isSelected = selectedMeetingId == meeting.id
        let isHovered = hoveredMeetingId == meeting.id

        return Button {
            selectedMeetingId = meeting.id
        } label: {
            HStack(alignment: .top, spacing: 10) {
                // Template icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(templateColor(meeting.template).opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: meeting.template.icon)
                        .font(.system(size: 13))
                        .foregroundColor(templateColor(meeting.template))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(meeting.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(MMColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(meeting.date.formatted(date: .omitted, time: .shortened))
                        Text("·")
                        Text(formatDuration(meeting.duration))
                        if !meeting.briefActionItems.isEmpty {
                            Text("·")
                            Text("\(meeting.briefActionItems.count) actions")
                        }
                    }
                    .font(.system(size: 10))
                    .foregroundColor(MMColors.textTertiary)
                    .lineLimit(1)
                }

                Spacer(minLength: 0)

                // Status dot
                statusDot(meeting.status)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? MMColors.primary.opacity(0.08) : (isHovered ? MMColors.background : Color.clear))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? MMColors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredMeetingId = hovering ? meeting.id : nil
        }
    }

    @ViewBuilder
    private func statusDot(_ status: MeetingStatus) -> some View {
        switch status {
        case .complete:
            Circle()
                .fill(MMColors.success)
                .frame(width: 6, height: 6)
        case .processing:
            ProgressView()
                .scaleEffect(0.4)
                .frame(width: 12, height: 12)
        case .recording:
            Circle()
                .fill(MMColors.recording)
                .frame(width: 6, height: 6)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 10))
                .foregroundColor(.red)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 28))
                .foregroundColor(MMColors.textTertiary.opacity(0.5))
            Text(searchText.isEmpty ? "No meetings yet" : "No results")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(MMColors.textSecondary)
            if searchText.isEmpty {
                Text("Start a recording to capture your first meeting")
                    .font(.system(size: 11))
                    .foregroundColor(MMColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }

    // MARK: - Helpers

    private func templateColor(_ template: MeetingTemplate) -> Color {
        switch template {
        case .general:    return MMColors.primary
        case .oneOnOne:   return MMColors.info
        case .salesCall:  return MMColors.success
        case .interview:  return MMColors.warning
        case .standup:    return Color.orange
        case .discovery:  return Color.purple
        case .brainstorm: return Color.pink
        }
    }

    private struct MeetingGroup: Identifiable {
        let key: String
        let meetings: [Meeting]
        var id: String { key }
    }

    private var filteredMeetings: [Meeting] {
        if searchText.isEmpty { return meetingService.meetings }
        return meetingService.meetings.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.clientName ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedMeetings: [MeetingGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredMeetings) { meeting -> String in
            if calendar.isDateInToday(meeting.date) { return "Today" }
            if calendar.isDateInYesterday(meeting.date) { return "Yesterday" }
            if calendar.isDate(meeting.date, equalTo: Date(), toGranularity: .weekOfYear) { return "This Week" }
            return meeting.date.formatted(date: .abbreviated, time: .omitted)
        }
        let order = ["Today", "Yesterday", "This Week"]
        return grouped.map { MeetingGroup(key: $0.key, meetings: $0.value.sorted { $0.date > $1.date }) }
            .sorted { a, b in
                let ai = order.firstIndex(of: a.key) ?? Int.max
                let bi = order.firstIndex(of: b.key) ?? Int.max
                if ai != bi { return ai < bi }
                return a.key > b.key
            }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}

extension Notification.Name {
    static let macStartRecording = Notification.Name("macStartRecording")
}
#endif
