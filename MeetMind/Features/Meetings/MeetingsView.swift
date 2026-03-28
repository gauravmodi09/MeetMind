import SwiftUI

struct MeetingsView: View {
    @EnvironmentObject var meetingService: MeetingService
    @StateObject private var audioService = AudioRecordingService.shared

    @State private var showRecording = false
    @State private var showProcessing = false
    @State private var processingMeeting: Meeting?
    @State private var selectedMeeting: Meeting?
    @State private var copiedMeetingId: UUID?
    @State private var meetingToDelete: Meeting?
    @State private var showDeleteConfirm = false
    @State private var pulseGlow = false
    @State private var cardsAppeared = false
    @State private var showCalendar = false
    @State private var showMeetingPrep = false
    @State private var showSearch = false
    @State private var showSpaces = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated floating orb background
                AnimatedMeshBackground()

                if meetingService.meetings.isEmpty && !showRecording {
                    emptyState
                } else {
                    mainContent
                }
            }
            .overlay(alignment: .top) {
                if audioService.isRecording && !showRecording {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(MMColors.recording)
                            .frame(width: 8, height: 8)
                        Text("Recording...")
                            .font(MMTypography.caption1)
                            .foregroundColor(.white)
                        Spacer()
                        Text(formattedRecordingTime)
                            .font(MMTypography.monoSmall)
                            .foregroundColor(.white)
                        Button("Return") {
                            showRecording = true
                        }
                        .font(MMTypography.footnoteMedium)
                        .foregroundColor(MMColors.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(red: 26/255, green: 26/255, blue: 46/255))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
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
                    },
                    onMinimize: {
                        showRecording = false
                    }
                )
                .environmentObject(meetingService)
            }
            .sheet(isPresented: $showMeetingPrep) {
                MeetingPrepView(
                    clientName: nil,
                    onStartRecording: {
                        showMeetingPrep = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showRecording = true
                        }
                    },
                    onDismiss: {
                        showMeetingPrep = false
                    }
                )
            }
            .sheet(isPresented: $showSearch) {
                NavigationStack {
                    GlobalSearchView()
                }
            }
            .sheet(isPresented: $showSpaces) {
                NavigationStack {
                    SpacesView()
                }
            }
            .navigationDestination(item: $selectedMeeting) { meeting in
                MeetingDetailView(meeting: meeting)
            }
            .onReceive(NotificationCenter.default.publisher(for: .autoStartRecording)) { _ in
                if !showRecording {
                    showRecording = true
                }
            }
            .alert("Delete Meeting?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) { meetingToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let meeting = meetingToDelete {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.warning)
                        meetingService.deleteMeeting(meeting)
                        meetingToDelete = nil
                    }
                }
            } message: {
                Text("This will permanently delete \"\(meetingToDelete?.title ?? "this meeting")\" and its notes.")
            }
        }
    }

    // MARK: - Greeting Header

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 5 && hour < 12 {
            return "Good morning"
        } else if hour >= 12 && hour < 17 {
            return "Good afternoon"
        } else {
            return "Good evening"
        }
    }

    private var todayMeetingCount: Int {
        meetingService.meetings.filter { Calendar.current.isDateInToday($0.date) }.count
    }

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(MMColors.textPrimary)

            Text(todayMeetingCount > 0
                 ? "You have \(todayMeetingCount) meeting\(todayMeetingCount == 1 ? "" : "s") today"
                 : "No meetings yet today")
                .font(MMTypography.subheadline)
                .foregroundColor(MMColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }

    // MARK: - Quick Action Chips

    private var quickActionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                quickChip(icon: "mic.fill", label: "Record Meeting") {
                    let context = MeetingPrepService.shared.prepareContext(for: nil)
                    if context.hasContext {
                        showMeetingPrep = true
                    } else {
                        showRecording = true
                    }
                }

                quickChip(icon: "checkmark.circle", label: "Voice Todo") {
                    NotificationCenter.default.post(name: .widgetVoiceTodo, object: nil)
                }

                quickChip(icon: "magnifyingglass", label: "Search") {
                    showSearch = true
                }

                quickChip(icon: "square.stack.3d.up", label: "Spaces") {
                    showSpaces = true
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func quickChip(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(MMColors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(MMColors.cardBg)
            )
            .overlay(
                Capsule()
                    .stroke(MMColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats Row

    private var totalPendingActionItems: Int {
        meetingService.meetings
            .flatMap { $0.briefActionItems }
            .filter { !$0.isCompleted }
            .count
    }

    private var recordingStreak: Int {
        let calendar = Calendar.current
        let meetingDates = Set(meetingService.meetings.map { calendar.startOfDay(for: $0.date) })
        guard !meetingDates.isEmpty else { return 0 }

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        // If no meeting today, start checking from yesterday
        if !meetingDates.contains(checkDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            checkDate = yesterday
        }

        while meetingDates.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        return streak
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            miniStatCard(value: "\(meetingService.meetings.count)", label: "Meetings", icon: "mic.fill", color: MMColors.primary)
            miniStatCard(value: "\(totalPendingActionItems)", label: "Pending", icon: "checklist", color: MMColors.warning)
            miniStatCard(value: "\(recordingStreak)", label: "Day Streak", icon: "flame.fill", color: MMColors.success)
        }
        .padding(.horizontal, 16)
    }

    private func miniStatCard(value: String, label: String, icon: String, color: Color) -> some View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .light)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(MMColors.border.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Greeting Header
                greetingHeader
                    .padding(.top, 12)

                // Quick Action Chips
                quickActionChips

                // Stats Row
                statsRow

                // Offline Queue Banner
                OfflineQueueBanner()
                    .padding(.horizontal, 16)

                // Today Summary Card
                todaySummaryCard
                    .padding(.horizontal, 16)

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

                // Calendar events
                DisclosureGroup(isExpanded: $showCalendar) {
                    UpcomingMeetingsView(onRecordTapped: { _ in
                        showMeetingPrep = true
                    })
                    .frame(maxHeight: 200)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundColor(MMColors.info)
                        Text("Today's Calendar")
                            .font(MMTypography.headline)
                            .foregroundColor(MMColors.textPrimary)
                    }
                }
                .padding(.horizontal, 16)

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
                                        onRetry: meeting.status == .failed ? {
                                            Task { await meetingService.reprocessMeeting(meeting) }
                                        } : nil,
                                        onDelete: {
                                            meetingToDelete = meeting
                                            showDeleteConfirm = true
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
        .refreshable {
            meetingService.loadMeetings()
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
        let completedTodos = todayActionCount - pendingTodos
        let completionRate = todayActionCount > 0 ? Double(completedTodos) / Double(todayActionCount) : 0.0

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        let todayString = dateFormatter.string(from: Date())

        return HStack(spacing: 0) {
            // Gradient accent line on left
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [MMColors.primary, MMColors.success],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)

            HStack(spacing: 16) {
                // Left content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Today")
                            .font(.system(size: 18, weight: .bold))
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

                            Text("No meetings yet — tap to record your first one")
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
                                label: "action\(todayActionCount == 1 ? "" : "s")",
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

                // Activity ring (only when there are items)
                if todayActionCount > 0 {
                    ZStack {
                        Circle()
                            .stroke(MMColors.glass, lineWidth: 4)
                            .frame(width: 44, height: 44)

                        Circle()
                            .trim(from: 0, to: completionRate)
                            .stroke(
                                LinearGradient(
                                    colors: [MMColors.success, MMColors.primary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(completionRate * 100))%")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(MMColors.textPrimary)
                    }
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .light)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)
        .shadow(color: MMColors.primary.opacity(0.1), radius: 12, x: 0, y: 4)
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
                let context = MeetingPrepService.shared.prepareContext(for: nil)
                if context.hasContext {
                    showMeetingPrep = true
                } else {
                    showRecording = true
                }
            } label: {
                ZStack {
                    // Outer ambient glow
                    Circle()
                        .fill(MMColors.primary.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .blur(radius: 30)
                        .scaleEffect(pulseGlow ? 1.2 : 0.8)
                        .opacity(pulseGlow ? 0.8 : 0.4)

                    // Secondary pulsing ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [MMColors.primary.opacity(0.6), MMColors.primary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 110, height: 110)
                        .scaleEffect(pulseGlow ? 1.15 : 0.95)
                        .opacity(pulseGlow ? 0.0 : 0.8)

                    // Frosted glass backing for the button
                    Circle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .light)
                        .frame(width: 88, height: 88)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.8), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)

                    // The actual button core
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [MMColors.primary, MMColors.primaryDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .shadow(color: MMColors.primary.opacity(0.6), radius: 16, x: 0, y: 4)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                        .shimmer() // Add the premium shimmer effect
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

            Text("Record Meeting")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(MMColors.textSecondary)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 32) {
            Spacer()

            recordButton

            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(MMColors.primary)
                    .shimmer()

                Text("Your AI Meeting Assistant")
                    .font(MMTypography.title3)
                    .foregroundColor(MMColors.textPrimary)

                Text("Tap the mic to start capturing your meeting.\nMeetMind will create a summary and action items.")
                    .font(MMTypography.subheadline)
                    .foregroundColor(MMColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .glassmorphic(padding: 24)
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Helpers

    private var sortedMeetings: [Meeting] {
        meetingService.meetings.sorted { $0.date > $1.date }
    }

    private var formattedRecordingTime: String {
        let totalSeconds = Int(audioService.duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
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

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

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
