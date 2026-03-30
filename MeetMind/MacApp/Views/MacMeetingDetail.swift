#if os(macOS)
import SwiftUI

struct MacMeetingDetail: View {
    let meeting: Meeting
    @State private var activeTab: DetailTab = .summary

    enum DetailTab: String, CaseIterable {
        case summary = "Summary"
        case transcript = "Transcript"
        case actions = "Action Items"
        case notes = "Notes"
        case chat = "AI Chat"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meeting.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.180))

                    HStack(spacing: 8) {
                        Text(meeting.date.formatted(date: .abbreviated, time: .shortened))
                        Text("·")
                        Text(formatDuration(meeting.duration))
                        if let client = meeting.clientName {
                            Text("·")
                            Text(client)
                        }
                        Text("·")
                        Text(meeting.status.displayName)
                            .foregroundColor(statusColor)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    macActionButton("Export", icon: "square.and.arrow.up")
                    macActionButton("Share", icon: "paperplane")
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            // Tab bar
            HStack(spacing: 0) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Button {
                        activeTab = tab
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: activeTab == tab ? .semibold : .regular))
                            .foregroundColor(activeTab == tab ? MMColors.primary : .secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .overlay(alignment: .bottom) {
                                if activeTab == tab {
                                    Rectangle()
                                        .fill(MMColors.primary)
                                        .frame(height: 2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .overlay(alignment: .bottom) {
                Divider()
            }
            .padding(.horizontal, 24)

            // Tab content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch activeTab {
                    case .summary:
                        summaryTab
                    case .transcript:
                        transcriptTab
                    case .actions:
                        actionsTab
                    case .notes:
                        notesTab
                    case .chat:
                        chatTab
                    }
                }
                .padding(24)
            }
        }
        .background(Color.white)
    }

    // MARK: - Summary Tab

    private var summaryTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let summary = meeting.briefSummary {
                detailSection("Key Points") {
                    Text(summary)
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.267, green: 0.267, blue: 0.267))
                        .lineSpacing(4)
                        .textSelection(.enabled)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 0.98, green: 0.98, blue: 0.98)))
                }
            }

            if !meeting.briefDecisions.isEmpty {
                detailSection("Decisions") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(meeting.briefDecisions, id: \.self) { decision in
                            HStack(alignment: .top, spacing: 8) {
                                Text("→")
                                    .foregroundColor(MMColors.primary)
                                    .font(.system(size: 14))
                                Text(decision)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(red: 0.267, green: 0.267, blue: 0.267))
                            }
                        }
                    }
                }
            }

            if !meeting.briefActionItems.isEmpty {
                detailSection("Action Items (\(meeting.briefActionItems.count))") {
                    VStack(spacing: 6) {
                        ForEach(meeting.briefActionItems) { item in
                            actionItemRow(item)
                        }
                    }
                }
            }

            if !meeting.briefKeyTopics.isEmpty {
                detailSection("Key Topics") {
                    FlowLayout(spacing: 6) {
                        ForEach(meeting.briefKeyTopics, id: \.self) { topic in
                            Text(topic)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(MMColors.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(MMColors.primary.opacity(0.1))
                                )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Transcript Tab

    private var transcriptTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let transcript = meeting.rawTranscript, !transcript.isEmpty {
                Text(transcript)
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.267, green: 0.267, blue: 0.267))
                    .lineSpacing(4)
                    .textSelection(.enabled)
            } else {
                emptyState(icon: "text.alignleft", message: "No transcript available")
            }
        }
    }

    // MARK: - Actions Tab

    private var actionsTab: some View {
        VStack(alignment: .leading, spacing: 6) {
            if meeting.briefActionItems.isEmpty {
                emptyState(icon: "checkmark.circle", message: "No action items")
            } else {
                ForEach(meeting.briefActionItems) { item in
                    actionItemRow(item)
                }
            }
        }
    }

    // MARK: - Notes Tab

    private var notesTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let notes = meeting.userNotes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 13))
                    .lineSpacing(4)
                    .textSelection(.enabled)
            } else if let notepad = meeting.notepadContent, !notepad.isEmpty {
                Text(notepad)
                    .font(.system(size: 13))
                    .lineSpacing(4)
                    .textSelection(.enabled)
            } else {
                emptyState(icon: "note.text", message: "No notes for this meeting")
            }
        }
    }

    // MARK: - Chat Tab

    private var chatTab: some View {
        VStack {
            emptyState(icon: "bubble.left.and.bubble.right", message: "AI Chat — coming soon on macOS")
        }
    }

    // MARK: - Components

    private func detailSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.180))
            content()
        }
    }

    private func actionItemRow(_ item: ActionItem) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundColor(item.isCompleted ? Color(red: 0.063, green: 0.725, blue: 0.506) : Color(white: 0.8))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.text)
                    .font(.system(size: 12))
                    .foregroundColor(item.isCompleted ? .secondary : Color(red: 0.2, green: 0.2, blue: 0.2))
                    .strikethrough(item.isCompleted)

                HStack(spacing: 4) {
                    if !item.owner.isEmpty {
                        Text(item.owner)
                    }
                    if let due = item.dueDate {
                        Text("· Due \(due.formatted(date: .abbreviated, time: .omitted))")
                    }
                }
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.98, green: 0.98, blue: 0.98)))
    }

    private func macActionButton(_ title: String, icon: String) -> some View {
        Button {} label: {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10))
                Text(title).font(.system(size: 11))
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(red: 0.94, green: 0.94, blue: 0.96)))
        }
        .buttonStyle(.plain)
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var statusColor: Color {
        switch meeting.status {
        case .complete:   return Color(red: 0.063, green: 0.725, blue: 0.506)
        case .processing: return Color(red: 0.961, green: 0.620, blue: 0.043)
        case .recording:  return .red
        case .failed:     return .red
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
#endif
