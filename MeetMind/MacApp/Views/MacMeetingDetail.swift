#if os(macOS)
import SwiftUI
import AppKit

struct MacMeetingDetail: View {
    let meeting: Meeting
    @EnvironmentObject var meetingService: MeetingService
    @State private var activeTab: DetailTab = .summary
    @State private var hoveredTab: DetailTab?

    // Export / Share
    @State private var showCopied: Bool = false

    // Email tab
    @State private var generatedEmail: String = ""
    @State private var isGeneratingEmail: Bool = false
    @State private var emailError: String? = nil

    // Coach tab
    @State private var coachReport: String = ""
    @State private var isGeneratingCoach: Bool = false
    @State private var coachError: String? = nil

    enum DetailTab: String, CaseIterable {
        case summary    = "Summary"
        case transcript = "Transcript"
        case actions    = "Action Items"
        case notes      = "Notes"
        case chat       = "AI Chat"
        case email      = "Email"
        case coach      = "Coach"

        var icon: String {
            switch self {
            case .summary:    return "doc.text"
            case .transcript: return "text.alignleft"
            case .actions:    return "checkmark.circle"
            case .notes:      return "note.text"
            case .chat:       return "bubble.left.and.bubble.right"
            case .email:      return "envelope"
            case .coach:      return "figure.mind.and.body"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerView
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 16)

            // Tab bar
            tabBar
                .padding(.horizontal, 28)

            Divider()

            // Tab content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch activeTab {
                    case .summary:    summaryTab
                    case .transcript: transcriptTab
                    case .actions:    actionsTab
                    case .notes:      notesTab
                    case .chat:       chatTab
                    case .email:      emailTab
                    case .coach:      coachTab
                    }
                }
                .padding(28)
            }
        }
        .background(MMColors.backgroundElevated)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(meeting.template.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(MMColors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(MMColors.primary.opacity(0.1))
                        )
                    statusBadge
                }

                Text(meeting.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(MMColors.textPrimary)

                HStack(spacing: 6) {
                    Label(meeting.date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    Text("·")
                    Label(formatDuration(meeting.duration), systemImage: "clock")
                    if let client = meeting.clientName {
                        Text("·")
                        Label(client, systemImage: "building.2")
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(MMColors.textSecondary)
            }

            Spacer()

            HStack(spacing: 8) {
                exportButton
                shareButton
            }
        }
    }

    private var exportButton: some View {
        Button {
            exportMeeting()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "square.and.arrow.up").font(.system(size: 11))
                Text("Export").font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(MMColors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(MMColors.background)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(MMColors.border))
            )
        }
        .buttonStyle(.plain)
    }

    private var shareButton: some View {
        Button {
            shareMeeting()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: showCopied ? "checkmark" : "paperplane").font(.system(size: 11))
                Text(showCopied ? "Copied!" : "Share").font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(showCopied ? MMColors.success : MMColors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(showCopied ? MMColors.success.opacity(0.08) : MMColors.background)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(showCopied ? MMColors.success.opacity(0.3) : MMColors.border))
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: showCopied)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(meeting.status.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(statusColor)
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        activeTab = tab
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 11))
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: activeTab == tab ? .semibold : .regular))
                    }
                    .foregroundColor(activeTab == tab ? MMColors.primary : MMColors.textTertiary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(activeTab == tab ? MMColors.primary.opacity(0.08) : (hoveredTab == tab ? MMColors.background : Color.clear))
                    )
                }
                .buttonStyle(.plain)
                .onHover { h in hoveredTab = h ? tab : nil }
            }
            Spacer()
        }
    }

    // MARK: - Summary Tab

    private var summaryTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let summary = meeting.briefSummary {
                detailSection("Key Points", icon: "sparkles") {
                    Text(summary)
                        .font(.system(size: 13, design: .default))
                        .foregroundColor(MMColors.textSecondary)
                        .lineSpacing(5)
                        .textSelection(.enabled)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(MMColors.background)
                        )
                }
            }

            if !meeting.briefDecisions.isEmpty {
                detailSection("Decisions", icon: "arrow.right.circle") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(meeting.briefDecisions, id: \.self) { decision in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(MMColors.success)
                                    .frame(width: 16)
                                Text(decision)
                                    .font(.system(size: 13))
                                    .foregroundColor(MMColors.textSecondary)
                                    .lineSpacing(3)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(MMColors.success.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(MMColors.success.opacity(0.1))
                            )
                    )
                }
            }

            if !meeting.briefActionItems.isEmpty {
                detailSection("Action Items (\(meeting.briefActionItems.count))", icon: "checkmark.circle") {
                    VStack(spacing: 6) {
                        ForEach(meeting.briefActionItems) { item in
                            actionItemRow(item)
                        }
                    }
                }
            }

            if !meeting.briefKeyTopics.isEmpty {
                detailSection("Key Topics", icon: "tag") {
                    FlowLayout(spacing: 6) {
                        ForEach(meeting.briefKeyTopics, id: \.self) { topic in
                            Text(topic)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(MMColors.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(MMColors.primary.opacity(0.08))
                                )
                        }
                    }
                }
            }

            if !meeting.briefKeyQuotes.isEmpty {
                detailSection("Key Quotes", icon: "quote.opening") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(meeting.briefKeyQuotes, id: \.self) { quote in
                            HStack(alignment: .top, spacing: 10) {
                                Rectangle()
                                    .fill(MMColors.primary.opacity(0.3))
                                    .frame(width: 3)
                                    .cornerRadius(2)
                                Text(quote)
                                    .font(.system(size: 13))
                                    .italic()
                                    .foregroundColor(MMColors.textSecondary)
                                    .lineSpacing(3)
                            }
                            .padding(.vertical, 4)
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
                    .foregroundColor(MMColors.textSecondary)
                    .lineSpacing(5)
                    .textSelection(.enabled)
            } else {
                emptyState(icon: "text.alignleft", title: "No transcript available", message: "The transcript will appear here after processing")
            }
        }
    }

    // MARK: - Actions Tab

    private var actionsTab: some View {
        VStack(alignment: .leading, spacing: 8) {
            if meeting.briefActionItems.isEmpty {
                emptyState(icon: "checkmark.circle", title: "No action items", message: "Action items extracted from the meeting will appear here")
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
                    .lineSpacing(5)
                    .textSelection(.enabled)
                    .foregroundColor(MMColors.textSecondary)
            } else if let notepad = meeting.notepadContent, !notepad.isEmpty {
                Text(notepad)
                    .font(.system(size: 13))
                    .lineSpacing(5)
                    .textSelection(.enabled)
                    .foregroundColor(MMColors.textSecondary)
            } else {
                emptyState(icon: "note.text", title: "No notes", message: "Notes taken during the meeting will appear here")
            }
        }
    }

    // MARK: - Chat Tab

    private var chatTab: some View {
        VStack(spacing: 12) {
            emptyState(icon: "bubble.left.and.bubble.right", title: "Ask about this meeting", message: "Use the AI Chat section to ask questions about this meeting")
        }
    }

    // MARK: - Email Tab

    private var emailTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            detailSection("Follow-up Email", icon: "envelope") {
                VStack(alignment: .leading, spacing: 14) {
                    if isGeneratingEmail {
                        HStack(spacing: 10) {
                            ProgressView()
                                .scaleEffect(0.75)
                                .frame(width: 16, height: 16)
                            Text("Generating follow-up email…")
                                .font(.system(size: 13))
                                .foregroundColor(MMColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 10).fill(MMColors.background))
                    } else if let error = emailError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(MMColors.warning)
                                .font(.system(size: 13))
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(MMColors.textSecondary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(MMColors.warning.opacity(0.06))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(MMColors.warning.opacity(0.2)))
                        )
                    } else if !generatedEmail.isEmpty {
                        Text(generatedEmail)
                            .font(.system(size: 13))
                            .foregroundColor(MMColors.textSecondary)
                            .lineSpacing(5)
                            .textSelection(.enabled)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 10).fill(MMColors.background))

                        HStack(spacing: 10) {
                            Button {
                                let pb = NSPasteboard.general
                                pb.clearContents()
                                pb.setString(generatedEmail, forType: .string)
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "doc.on.doc").font(.system(size: 11))
                                    Text("Copy to Clipboard").font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(MMColors.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(MMColors.primary.opacity(0.08))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(MMColors.primary.opacity(0.2)))
                                )
                            }
                            .buttonStyle(.plain)

                            Button {
                                generateEmail()
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "arrow.clockwise").font(.system(size: 11))
                                    Text("Regenerate").font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(MMColors.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(MMColors.background)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(MMColors.border))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        VStack(spacing: 14) {
                            Image(systemName: "envelope")
                                .font(.system(size: 32))
                                .foregroundColor(MMColors.textTertiary.opacity(0.4))
                            Text("Generate a professional follow-up email based on this meeting's summary, decisions, and action items.")
                                .font(.system(size: 13))
                                .foregroundColor(MMColors.textSecondary)
                                .multilineTextAlignment(.center)

                            Button {
                                generateEmail()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles").font(.system(size: 12))
                                    Text("Generate Follow-up Email").font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 9)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(MMColors.primary)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }
                }
            }
        }
    }

    // MARK: - Coach Tab

    private var coachTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            detailSection("Meeting Coach", icon: "figure.mind.and.body") {
                VStack(alignment: .leading, spacing: 14) {
                    if let transcript = meeting.rawTranscript, !transcript.isEmpty {
                        if isGeneratingCoach {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .scaleEffect(0.75)
                                    .frame(width: 16, height: 16)
                                Text("Analyzing your communication…")
                                    .font(.system(size: 13))
                                    .foregroundColor(MMColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 10).fill(MMColors.background))
                        } else if let error = coachError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(MMColors.warning)
                                    .font(.system(size: 13))
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundColor(MMColors.textSecondary)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(MMColors.warning.opacity(0.06))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(MMColors.warning.opacity(0.2)))
                            )
                        } else if !coachReport.isEmpty {
                            Text(coachReport)
                                .font(.system(size: 13))
                                .foregroundColor(MMColors.textSecondary)
                                .lineSpacing(5)
                                .textSelection(.enabled)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 10).fill(MMColors.background))

                            Button {
                                generateCoachReport(transcript: transcript)
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "arrow.clockwise").font(.system(size: 11))
                                    Text("Regenerate").font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(MMColors.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(MMColors.background)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(MMColors.border))
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            VStack(spacing: 14) {
                                Image(systemName: "figure.mind.and.body")
                                    .font(.system(size: 32))
                                    .foregroundColor(MMColors.textTertiary.opacity(0.4))
                                Text("Get personalized coaching feedback on your communication style, active listening, and persuasiveness based on this meeting's transcript.")
                                    .font(.system(size: 13))
                                    .foregroundColor(MMColors.textSecondary)
                                    .multilineTextAlignment(.center)

                                Button {
                                    generateCoachReport(transcript: transcript)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkles").font(.system(size: 12))
                                        Text("Generate Coach Report").font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 9)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(MMColors.primary)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        }
                    } else {
                        emptyState(
                            icon: "figure.mind.and.body",
                            title: "No transcript available",
                            message: "A transcript is required to generate a coaching report. Process this meeting first."
                        )
                    }
                }
            }
        }
    }

    // MARK: - Components

    private func detailSection<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(MMColors.primary)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MMColors.textPrimary)
            }
            content()
        }
    }

    private func actionItemRow(_ item: ActionItem) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18))
                .foregroundColor(item.isCompleted ? MMColors.success : MMColors.border)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.text)
                    .font(.system(size: 13))
                    .foregroundColor(item.isCompleted ? MMColors.textTertiary : MMColors.textPrimary)
                    .strikethrough(item.isCompleted)

                HStack(spacing: 6) {
                    if !item.owner.isEmpty {
                        Label(item.owner, systemImage: "person.fill")
                    }
                    if let due = item.dueDate {
                        Label(due.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    }
                    if item.isMine {
                        Text("Mine")
                            .foregroundColor(MMColors.primary)
                    }
                }
                .font(.system(size: 10))
                .foregroundColor(MMColors.textTertiary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(MMColors.background)
        )
    }

    private func macActionButton(_ title: String, icon: String) -> some View {
        Button {} label: {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 11))
                Text(title).font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(MMColors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(MMColors.background)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(MMColors.border))
            )
        }
        .buttonStyle(.plain)
    }

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(MMColors.textTertiary.opacity(0.4))
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(MMColors.textSecondary)
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(MMColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var statusColor: Color {
        switch meeting.status {
        case .complete:   return MMColors.success
        case .processing: return MMColors.warning
        case .recording:  return MMColors.recording
        case .failed:     return .red
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    // MARK: - Actions

    private func exportMeeting() {
        let content = buildExportText()
        let panel = NSSavePanel()
        panel.title = "Export Meeting"
        panel.nameFieldStringValue = "\(meeting.title).txt"
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func buildExportText() -> String {
        var lines: [String] = []
        lines.append("MEETING: \(meeting.title)")
        lines.append("Date: \(meeting.date.formatted(date: .long, time: .shortened))")
        lines.append("Duration: \(formatDuration(meeting.duration))")
        if let client = meeting.clientName {
            lines.append("Client: \(client)")
        }
        lines.append(String(repeating: "-", count: 60))

        if let summary = meeting.briefSummary {
            lines.append("")
            lines.append("SUMMARY")
            lines.append(summary)
        }

        if !meeting.briefDecisions.isEmpty {
            lines.append("")
            lines.append("DECISIONS")
            for decision in meeting.briefDecisions {
                lines.append("• \(decision)")
            }
        }

        if !meeting.briefActionItems.isEmpty {
            lines.append("")
            lines.append("ACTION ITEMS")
            for item in meeting.briefActionItems {
                let check = item.isCompleted ? "[x]" : "[ ]"
                var line = "\(check) \(item.text)"
                if !item.owner.isEmpty { line += " — \(item.owner)" }
                lines.append(line)
            }
        }

        if !meeting.briefKeyTopics.isEmpty {
            lines.append("")
            lines.append("KEY TOPICS")
            lines.append(meeting.briefKeyTopics.joined(separator: ", "))
        }

        if !meeting.briefKeyQuotes.isEmpty {
            lines.append("")
            lines.append("KEY QUOTES")
            for quote in meeting.briefKeyQuotes {
                lines.append("\"\(quote)\"")
            }
        }

        return lines.joined(separator: "\n")
    }

    private func shareMeeting() {
        var parts: [String] = []
        parts.append(meeting.title)
        if let summary = meeting.briefSummary { parts.append(summary) }
        if !meeting.briefDecisions.isEmpty {
            parts.append("Decisions: " + meeting.briefDecisions.joined(separator: "; "))
        }
        if !meeting.briefActionItems.isEmpty {
            let itemTexts = meeting.briefActionItems.map { $0.text }
            parts.append("Actions: " + itemTexts.joined(separator: "; "))
        }
        let brief = parts.joined(separator: "\n\n")
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(brief, forType: .string)

        withAnimation { showCopied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showCopied = false }
        }
    }

    private func generateEmail() {
        isGeneratingEmail = true
        emailError = nil

        var briefParts: [String] = []
        if let summary = meeting.briefSummary { briefParts.append(summary) }
        if !meeting.briefDecisions.isEmpty {
            briefParts.append("Decisions:\n" + meeting.briefDecisions.map { "- \($0)" }.joined(separator: "\n"))
        }
        if !meeting.briefActionItems.isEmpty {
            briefParts.append("Action Items:\n" + meeting.briefActionItems.map { "- \($0.text)" }.joined(separator: "\n"))
        }
        let brief = briefParts.joined(separator: "\n\n")

        Task {
            do {
                let result = try await GroqService.shared.generateFollowUpEmail(brief: brief, meetingTitle: meeting.title)
                await MainActor.run {
                    generatedEmail = result
                    isGeneratingEmail = false
                }
            } catch {
                await MainActor.run {
                    emailError = error.localizedDescription
                    isGeneratingEmail = false
                }
            }
        }
    }

    private func generateCoachReport(transcript: String) {
        isGeneratingCoach = true
        coachError = nil

        let prompt = "Analyze the communication style of the first speaker (the user) in this meeting transcript. Provide specific, actionable feedback on: clarity of communication, active listening indicators, persuasiveness, areas for improvement, and things done well. Be constructive and specific with examples from the transcript."

        Task {
            do {
                let result = try await GroqService.shared.executeRecipe(prompt: prompt, transcript: transcript)
                await MainActor.run {
                    coachReport = result
                    isGeneratingCoach = false
                }
            } catch {
                await MainActor.run {
                    coachError = error.localizedDescription
                    isGeneratingCoach = false
                }
            }
        }
    }
}
#endif
