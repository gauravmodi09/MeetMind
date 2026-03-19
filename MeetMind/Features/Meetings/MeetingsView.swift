import SwiftUI

struct MeetingsView: View {
    @EnvironmentObject var meetingService: MeetingService
    @StateObject private var audioService = AudioRecordingService.shared

    @State private var showRecording = false
    @State private var showProcessing = false
    @State private var processingMeeting: Meeting?
    @State private var selectedMeeting: Meeting?
    @State private var copiedMeetingId: UUID?
    @State private var pulseGlow = false
    @State private var cardsAppeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [MMColors.background, MMColors.backgroundElevated],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if meetingService.meetings.isEmpty && !showRecording {
                    emptyState
                } else {
                    mainContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Meetings")
                            .font(MMTypography.title2)
                            .foregroundColor(MMColors.textPrimary)
                        Text(todayDateString)
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.textSecondary)
                    }
                }
            }
            .fullScreenCover(isPresented: $showRecording) {
                RecordingView(
                    onStop: { meeting in
                        showRecording = false
                        if let meeting {
                            processingMeeting = meeting
                            showProcessing = true
                            Task {
                                await meetingService.stopRecording()
                                await MainActor.run {
                                    showProcessing = false
                                    processingMeeting = nil
                                    if let completed = meetingService.meetings.first(where: { $0.status == .complete }) {
                                        selectedMeeting = completed
                                    }
                                }
                            }
                        }
                    },
                    onCancel: {
                        showRecording = false
                        meetingService.cancelRecording()
                    }
                )
                .environmentObject(meetingService)
            }
            .navigationDestination(item: $selectedMeeting) { meeting in
                MeetingDetailView(meeting: meeting)
            }
            .onReceive(NotificationCenter.default.publisher(for: .autoStartRecording)) { _ in
                if !showRecording {
                    showRecording = true
                }
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Today Summary Card
                todaySummaryCard
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // Record Button (Hero)
                recordButton

                // Processing Card
                if showProcessing, let meeting = processingMeeting {
                    ProcessingView(meeting: meeting) {
                        showProcessing = false
                        processingMeeting = nil
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Recent Meetings
                if !meetingService.meetings.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Meetings")
                            .font(MMTypography.headline)
                            .foregroundColor(MMColors.textPrimary)
                            .padding(.horizontal, 16)

                        LazyVStack(spacing: 8) {
                            ForEach(Array(sortedMeetings.enumerated()), id: \.element.id) { index, meeting in
                                Button {
                                    selectedMeeting = meeting
                                } label: {
                                    MeetingCard(
                                        meeting: meeting,
                                        onCopy: {
                                            copyBrief(for: meeting)
                                        },
                                        onChangeClient: { newClient in
                                            meetingService.updateMeetingClient(meeting, newClient: newClient)
                                        },
                                        availableClients: meetingService.allClientNames
                                    )
                                }
                                .buttonStyle(.plain)
                                .opacity(cardsAppeared ? 1 : 0)
                                .offset(y: cardsAppeared ? 0 : 20)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                        .delay(Double(index) * 0.1),
                                    value: cardsAppeared
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .onAppear {
            withAnimation {
                cardsAppeared = true
            }
        }
    }

    // MARK: - Today Summary Card

    private var todaySummaryCard: some View {
        let todayMeetings = meetingService.meetings.filter { Calendar.current.isDateInToday($0.date) }
        let todayMeetingCount = todayMeetings.count
        let todayActionItems = todayMeetings.flatMap { $0.briefActionItems }
        let todayActionCount = todayActionItems.count
        let pendingTodos = todayActionItems.filter { !$0.isCompleted }.count

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        let todayString = dateFormatter.string(from: Date())

        return HStack(spacing: 0) {
            // Purple accent line on left
            Rectangle()
                .fill(MMColors.primary)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Today")
                        .font(MMTypography.headline)
                        .foregroundColor(MMColors.textPrimary)

                    Spacer()

                    Text(todayString)
                        .font(MMTypography.caption1)
                        .foregroundColor(MMColors.textTertiary)
                }

                if todayMeetingCount == 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 12))
                            .foregroundColor(MMColors.textTertiary)

                        Text("No meetings yet -- tap to record your first one")
                            .font(MMTypography.footnote)
                            .foregroundColor(MMColors.textSecondary)
                    }
                } else {
                    HStack(spacing: 16) {
                        todayStatItem(
                            value: "\(todayMeetingCount)",
                            label: "meeting\(todayMeetingCount == 1 ? "" : "s")",
                            icon: "mic.fill",
                            color: MMColors.primary
                        )

                        todayStatItem(
                            value: "\(todayActionCount)",
                            label: "action item\(todayActionCount == 1 ? "" : "s")",
                            icon: "checklist",
                            color: MMColors.success
                        )

                        todayStatItem(
                            value: "\(pendingTodos)",
                            label: "pending",
                            icon: "clock",
                            color: MMColors.warning
                        )
                    }
                }
            }
            .padding(16)
        }
        .background(MMColors.cardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MMColors.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }

    private func todayStatItem(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(MMColors.textPrimary)

                Text(label)
                    .font(MMTypography.caption2)
                    .foregroundColor(MMColors.textTertiary)
            }
        }
    }

    // MARK: - Record Button

    private var recordButton: some View {
        VStack(spacing: 8) {
            Button {
                showRecording = true
            } label: {
                ZStack {
                    // Pulsing glow ring
                    Circle()
                        .stroke(MMColors.primary.opacity(0.3), lineWidth: 3)
                        .frame(width: 96, height: 96)
                        .scaleEffect(pulseGlow ? 1.15 : 0.95)
                        .opacity(pulseGlow ? 0.0 : 0.6)

                    Circle()
                        .stroke(MMColors.primary.opacity(0.15), lineWidth: 2)
                        .frame(width: 112, height: 112)
                        .scaleEffect(pulseGlow ? 1.25 : 0.9)
                        .opacity(pulseGlow ? 0.0 : 0.4)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [MMColors.primary, MMColors.primary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .shadow(color: MMColors.primary.opacity(0.4), radius: 16, x: 0, y: 4)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .accessibilityLabel("Record meeting")
            .accessibilityHint("Double-tap to start recording a new meeting")
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: false)
                ) {
                    pulseGlow = true
                }
            }

            Text("Tap to Record")
                .font(MMTypography.footnote)
                .foregroundColor(MMColors.textSecondary)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 32) {
            Spacer()

            recordButton

            VStack(spacing: 8) {
                Text("Record your first meeting")
                    .font(MMTypography.title3)
                    .foregroundColor(MMColors.textPrimary)

                Text("Tap the mic to start capturing your meeting.\nMeetMind will create a summary and action items.")
                    .font(MMTypography.subheadline)
                    .foregroundColor(MMColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Helpers

    private var sortedMeetings: [Meeting] {
        meetingService.meetings.sorted { $0.date > $1.date }
    }

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    private func copyBrief(for meeting: Meeting) {
        let brief = MeetingBriefFormatter.format(meeting: meeting)
        UIPasteboard.general.string = brief
        copiedMeetingId = meeting.id

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if copiedMeetingId == meeting.id {
                copiedMeetingId = nil
            }
        }
    }
}

// MARK: - Meeting Brief Formatter

struct MeetingBriefFormatter {
    static func format(meeting: Meeting) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let dateStr = dateFormatter.string(from: meeting.date)

        let minutes = Int(meeting.duration) / 60
        let durationStr: String
        if minutes < 60 {
            durationStr = "\(minutes) min"
        } else {
            durationStr = "\(minutes / 60)h \(minutes % 60)m"
        }

        let clientStr = meeting.clientName ?? "General"

        var lines: [String] = []
        lines.append("\u{1F4CB} Meeting Brief \u{2014} \(meeting.title)")
        lines.append("\u{1F4C5} \(dateStr) \u{00B7} \(durationStr) \u{00B7} \(clientStr)")
        lines.append("")

        if let summary = meeting.briefSummary {
            lines.append("Summary:")
            lines.append(summary)
            lines.append("")
        }

        if !meeting.briefDecisions.isEmpty {
            lines.append("Decisions:")
            for decision in meeting.briefDecisions {
                lines.append("\u{2022} \(decision)")
            }
            lines.append("")
        }

        if !meeting.briefActionItems.isEmpty {
            lines.append("Action Items:")
            for item in meeting.briefActionItems {
                let dueStr: String
                if let due = item.dueDate {
                    let df = DateFormatter()
                    df.dateFormat = "MMM d"
                    dueStr = " (due: \(df.string(from: due)))"
                } else {
                    dueStr = ""
                }
                lines.append("\u{25A1} \(item.text) \u{2014} \(item.owner)\(dueStr)")
            }
            lines.append("")
        }

        if !meeting.briefKeyTopics.isEmpty {
            lines.append("Key Topics: \(meeting.briefKeyTopics.joined(separator: ", "))")
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Meeting Identifiable+Hashable for navigationDestination

extension Meeting: Hashable {
    static func == (lhs: Meeting, rhs: Meeting) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Preview

#Preview {
    MeetingsView()
        .environmentObject(MeetingService.shared)
}
