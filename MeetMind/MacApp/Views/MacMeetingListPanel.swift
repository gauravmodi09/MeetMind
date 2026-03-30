#if os(macOS)
import SwiftUI

struct MacMeetingListPanel: View {
    @EnvironmentObject var meetingService: MeetingService
    @Binding var selectedMeetingId: UUID?
    @State private var searchText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Meetings")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.180))
                Spacer()
                Button {
                    NotificationCenter.default.post(name: .macStartRecording, object: nil)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(RoundedRectangle(cornerRadius: 6).fill(MMColors.primary))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                TextField("Search meetings...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.88)))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 14)

            // Meeting list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(groupedMeetings, id: \.key) { group in
                        Text(group.key)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 6)

                        ForEach(group.meetings) { meeting in
                            meetingRow(meeting)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 6)
                        }
                    }
                }
            }
        }
        .frame(width: 240)
        .background(Color(red: 0.973, green: 0.973, blue: 0.980)) // #f8f8fa
    }

    private func meetingRow(_ meeting: Meeting) -> some View {
        Button {
            selectedMeetingId = meeting.id
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(meeting.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.180))
                        .lineLimit(1)
                    Spacer()
                    if meeting.status == .complete {
                        Circle()
                            .fill(Color(red: 0.063, green: 0.725, blue: 0.506))
                            .frame(width: 6, height: 6)
                    } else if meeting.status == .processing {
                        Circle()
                            .fill(Color(red: 0.961, green: 0.620, blue: 0.043))
                            .frame(width: 6, height: 6)
                    }
                }
                Text("\(meeting.date.formatted(date: .omitted, time: .shortened)) · \(formatDuration(meeting.duration))\(meeting.briefActionItems.isEmpty ? "" : " · \(meeting.briefActionItems.count) actions")")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(11)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectedMeetingId == meeting.id ? MMColors.primary : Color(white: 0.93), lineWidth: selectedMeetingId == meeting.id ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Grouping

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
