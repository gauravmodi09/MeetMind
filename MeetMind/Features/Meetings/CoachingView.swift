import SwiftUI

struct CoachingView: View {
    let report: MeetingCoachReport

    @State private var selectedSpeakerIndex: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - Header
                headerSection

                // MARK: - Speaker Picker
                if report.speakerMetrics.count > 1 {
                    speakerPicker
                }

                // MARK: - Metric Cards
                if let speaker = selectedMetrics {
                    overviewGrid(speaker)
                    fillerWordsCard(speaker)
                    talkRatioCard
                    paceCard(speaker)
                    monologueCard(speaker)
                    questionsCard(speaker)
                    interruptionsCard(speaker)

                    // MARK: - Tips
                    tipsSection(speaker)
                }
            }
            .padding(16)
        }
        .background(MMColors.background.ignoresSafeArea())
        .navigationTitle("Meeting Coach")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Selected Speaker

    private var selectedMetrics: SpeakerCoachMetrics? {
        guard report.speakerMetrics.indices.contains(selectedSpeakerIndex) else { return nil }
        return report.speakerMetrics[selectedSpeakerIndex]
    }

    // MARK: - Header

    private var headerSection: some View {
        MMCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "figure.mind.and.body")
                        .font(.system(size: 24))
                        .foregroundColor(MMColors.primary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Coaching Report")
                            .font(MMTypography.title3)
                            .foregroundColor(MMColors.textPrimary)

                        Text("Meeting duration: \(formatDuration(report.meetingDuration))")
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.textSecondary)
                    }

                    Spacer()
                }

                // Summary stats row
                HStack(spacing: 0) {
                    summaryPill(
                        value: "\(report.speakerMetrics.count)",
                        label: "Speakers",
                        icon: "person.2"
                    )
                    summaryPill(
                        value: "\(report.totalQuestions)",
                        label: "Questions",
                        icon: "questionmark.bubble"
                    )
                    summaryPill(
                        value: "\(report.totalFillerWords)",
                        label: "Fillers",
                        icon: "text.bubble"
                    )
                    summaryPill(
                        value: "\(report.totalInterruptions)",
                        label: "Interrupts",
                        icon: "hand.raised"
                    )
                }
            }
        }
    }

    private func summaryPill(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(MMColors.primary)
            Text(value)
                .font(MMTypography.monoMedium)
                .foregroundColor(MMColors.textPrimary)
            Text(label)
                .font(MMTypography.caption2)
                .foregroundColor(MMColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Speaker Picker

    private var speakerPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(report.speakerMetrics.enumerated()), id: \.element.id) { index, metrics in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSpeakerIndex = index
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 11))
                            Text(metrics.speaker)
                                .font(MMTypography.footnoteMedium)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedSpeakerIndex == index
                                ? MMColors.primary
                                : MMColors.cardBgElevated
                        )
                        .foregroundColor(
                            selectedSpeakerIndex == index
                                ? .white
                                : MMColors.textSecondary
                        )
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    selectedSpeakerIndex == index
                                        ? Color.clear
                                        : MMColors.glassStroke,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Overview Grid

    private func overviewGrid(_ speaker: SpeakerCoachMetrics) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricTile(
                icon: "chart.pie",
                title: "Talk Ratio",
                value: "\(Int(speaker.talkRatioPercent))%",
                color: talkRatioColor(speaker.talkRatioPercent)
            )
            metricTile(
                icon: "speedometer",
                title: "Pace",
                value: "\(Int(speaker.wordsPerMinute)) WPM",
                color: paceColor(speaker.wordsPerMinute)
            )
            metricTile(
                icon: "text.bubble",
                title: "Filler Words",
                value: "\(speaker.fillerWordCount)",
                color: fillerColor(speaker)
            )
            metricTile(
                icon: "questionmark.bubble",
                title: "Questions",
                value: "\(speaker.questionCount)",
                color: MMColors.info
            )
        }
    }

    private func metricTile(icon: String, title: String, value: String, color: Color) -> some View {
        MMCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                    Spacer()
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }

                Text(value)
                    .font(MMTypography.title2)
                    .foregroundColor(MMColors.textPrimary)

                Text(title)
                    .font(MMTypography.caption1)
                    .foregroundColor(MMColors.textSecondary)
            }
        }
    }

    // MARK: - Filler Words Card

    private func fillerWordsCard(_ speaker: SpeakerCoachMetrics) -> some View {
        MMCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(icon: "text.bubble", title: "Filler Words", color: fillerColor(speaker))

                if speaker.fillerBreakdown.isEmpty {
                    Text("No filler words detected")
                        .font(MMTypography.subheadline)
                        .foregroundColor(MMColors.textTertiary)
                } else {
                    let sorted = speaker.fillerBreakdown.sorted { $0.value > $1.value }
                    ForEach(sorted, id: \.key) { word, count in
                        HStack {
                            Text("\"\(word)\"")
                                .font(MMTypography.mono)
                                .foregroundColor(MMColors.textPrimary)
                            Spacer()

                            // Bar
                            let maxCount = sorted.first?.value ?? 1
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(fillerColor(speaker).opacity(0.3))
                                    .frame(width: geo.size.width * CGFloat(count) / CGFloat(maxCount))
                            }
                            .frame(width: 80, height: 6)

                            Text("\(count)")
                                .font(MMTypography.monoSmall)
                                .foregroundColor(MMColors.textSecondary)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Talk Ratio Card

    private var talkRatioCard: some View {
        MMCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(icon: "chart.pie", title: "Talk Ratio", color: MMColors.primary)

                ForEach(report.speakerMetrics) { metrics in
                    HStack(spacing: 12) {
                        Text(metrics.speaker)
                            .font(MMTypography.footnoteMedium)
                            .foregroundColor(MMColors.textPrimary)
                            .frame(width: 80, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(MMColors.cardBgElevated)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        metrics.id == selectedMetrics?.id
                                            ? MMColors.primary
                                            : MMColors.primary.opacity(0.4)
                                    )
                                    .frame(width: geo.size.width * metrics.talkRatioPercent / 100.0)
                            }
                        }
                        .frame(height: 12)

                        Text("\(Int(metrics.talkRatioPercent))%")
                            .font(MMTypography.monoSmall)
                            .foregroundColor(MMColors.textSecondary)
                            .frame(width: 36, alignment: .trailing)
                    }
                    .frame(height: 20)
                }
            }
        }
    }

    // MARK: - Pace Card

    private func paceCard(_ speaker: SpeakerCoachMetrics) -> some View {
        MMCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(icon: "speedometer", title: "Speaking Pace", color: paceColor(speaker.wordsPerMinute))

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(speaker.wordsPerMinute))")
                        .font(MMTypography.monoMedium)
                        .foregroundColor(MMColors.textPrimary)
                    Text("words per minute")
                        .font(MMTypography.caption1)
                        .foregroundColor(MMColors.textSecondary)
                }

                // Pace gauge
                paceGauge(wpm: speaker.wordsPerMinute)

                HStack {
                    Text("Slow")
                        .font(MMTypography.caption2)
                        .foregroundColor(MMColors.textTertiary)
                    Spacer()
                    Text("Ideal: 130-160")
                        .font(MMTypography.caption2)
                        .foregroundColor(MMColors.success)
                    Spacer()
                    Text("Fast")
                        .font(MMTypography.caption2)
                        .foregroundColor(MMColors.textTertiary)
                }
            }
        }
    }

    private func paceGauge(wpm: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(MMColors.cardBgElevated)

                // Ideal zone highlight
                let idealStart = 130.0 / 250.0
                let idealEnd = 160.0 / 250.0
                RoundedRectangle(cornerRadius: 4)
                    .fill(MMColors.success.opacity(0.15))
                    .frame(width: geo.size.width * (idealEnd - idealStart))
                    .offset(x: geo.size.width * idealStart)

                // Marker
                let position = min(max(wpm / 250.0, 0), 1.0)
                Circle()
                    .fill(paceColor(wpm))
                    .frame(width: 14, height: 14)
                    .shadow(color: paceColor(wpm).opacity(0.4), radius: 4)
                    .offset(x: geo.size.width * position - 7)
            }
        }
        .frame(height: 14)
    }

    // MARK: - Monologue Card

    private func monologueCard(_ speaker: SpeakerCoachMetrics) -> some View {
        MMCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(
                    icon: "person.wave.2",
                    title: "Longest Monologue",
                    color: monologueColor(speaker.longestMonologueSeconds)
                )

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formatDuration(speaker.longestMonologueSeconds))
                        .font(MMTypography.monoMedium)
                        .foregroundColor(MMColors.textPrimary)
                    Text("continuous speaking")
                        .font(MMTypography.caption1)
                        .foregroundColor(MMColors.textSecondary)
                }

                HStack(spacing: 8) {
                    severityBadge(
                        speaker.longestMonologueSeconds <= 90 ? .good :
                        speaker.longestMonologueSeconds <= 180 ? .okay : .needsWork
                    )
                    Text(
                        speaker.longestMonologueSeconds <= 90
                            ? "Good turn length"
                            : speaker.longestMonologueSeconds <= 180
                                ? "Consider shorter turns"
                                : "Break up long stretches"
                    )
                    .font(MMTypography.caption1)
                    .foregroundColor(MMColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Questions Card

    private func questionsCard(_ speaker: SpeakerCoachMetrics) -> some View {
        MMCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(icon: "questionmark.bubble", title: "Questions Asked", color: MMColors.info)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(speaker.questionCount)")
                        .font(MMTypography.monoMedium)
                        .foregroundColor(MMColors.textPrimary)
                    Text(speaker.questionCount == 1 ? "question asked" : "questions asked")
                        .font(MMTypography.caption1)
                        .foregroundColor(MMColors.textSecondary)
                }

                HStack(spacing: 8) {
                    severityBadge(speaker.questionCount >= 3 ? .good : speaker.questionCount >= 1 ? .okay : .needsWork)
                    Text(
                        speaker.questionCount >= 3
                            ? "Great engagement"
                            : speaker.questionCount >= 1
                                ? "Try asking more questions"
                                : "Questions show curiosity and engagement"
                    )
                    .font(MMTypography.caption1)
                    .foregroundColor(MMColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Interruptions Card

    private func interruptionsCard(_ speaker: SpeakerCoachMetrics) -> some View {
        MMCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(
                    icon: "hand.raised",
                    title: "Interruptions",
                    color: interruptionColor(speaker.interruptionCount)
                )

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(speaker.interruptionCount)")
                        .font(MMTypography.monoMedium)
                        .foregroundColor(MMColors.textPrimary)
                    Text(speaker.interruptionCount == 1 ? "interruption detected" : "interruptions detected")
                        .font(MMTypography.caption1)
                        .foregroundColor(MMColors.textSecondary)
                }

                if speaker.interruptionCount > 0 {
                    HStack(spacing: 8) {
                        severityBadge(speaker.interruptionCount > 3 ? .needsWork : .okay)
                        Text("Let others finish before responding")
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Tips Section

    private func tipsSection(_ speaker: SpeakerCoachMetrics) -> some View {
        let tips = MeetingCoachService.tips(for: speaker, meetingDuration: report.meetingDuration)

        return VStack(alignment: .leading, spacing: 12) {
            Text("COACHING TIPS")
                .font(MMTypography.overline)
                .foregroundColor(MMColors.textTertiary)
                .tracking(1.2)
                .padding(.top, 8)

            ForEach(tips) { tip in
                MMCard {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: tip.category.icon)
                            .font(.system(size: 16))
                            .foregroundColor(severityColor(tip.severity))
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text(tip.category.rawValue)
                                    .font(MMTypography.footnoteMedium)
                                    .foregroundColor(MMColors.textPrimary)
                                severityBadge(tip.severity)
                            }

                            Text(tip.message)
                                .font(MMTypography.caption1)
                                .foregroundColor(MMColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    // MARK: - Shared Components

    private func cardHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(title)
                .font(MMTypography.headline)
                .foregroundColor(MMColors.textPrimary)
            Spacer()
        }
    }

    private func severityBadge(_ severity: CoachingSeverity) -> some View {
        Text(severityLabel(severity))
            .font(MMTypography.caption2)
            .foregroundColor(severityColor(severity))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(severityColor(severity).opacity(0.15))
            .cornerRadius(8)
    }

    // MARK: - Color Helpers

    private func severityColor(_ severity: CoachingSeverity) -> Color {
        switch severity {
        case .good:      return MMColors.success
        case .okay:      return MMColors.warning
        case .needsWork: return MMColors.recording
        }
    }

    private func severityLabel(_ severity: CoachingSeverity) -> String {
        switch severity {
        case .good:      return "Good"
        case .okay:      return "OK"
        case .needsWork: return "Improve"
        }
    }

    private func talkRatioColor(_ ratio: Double) -> Color {
        if ratio > 70 || ratio < 20 { return MMColors.recording }
        if ratio > 60 || ratio < 25 { return MMColors.warning }
        return MMColors.success
    }

    private func paceColor(_ wpm: Double) -> Color {
        if wpm > 180 || (wpm < 100 && wpm > 0) { return MMColors.recording }
        if wpm > 160 || wpm < 120 { return MMColors.warning }
        return MMColors.success
    }

    private func fillerColor(_ speaker: SpeakerCoachMetrics) -> Color {
        let rate = speaker.totalSpeakingSeconds > 0
            ? Double(speaker.fillerWordCount) / (speaker.totalSpeakingSeconds / 60.0)
            : 0
        if rate > 5 { return MMColors.recording }
        if rate > 2 { return MMColors.warning }
        return MMColors.success
    }

    private func monologueColor(_ seconds: Double) -> Color {
        if seconds > 180 { return MMColors.recording }
        if seconds > 90 { return MMColors.warning }
        return MMColors.success
    }

    private func interruptionColor(_ count: Int) -> Color {
        if count > 3 { return MMColors.recording }
        if count > 0 { return MMColors.warning }
        return MMColors.success
    }

    // MARK: - Formatting

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if mins > 0 {
            return "\(mins)m \(secs)s"
        }
        return "\(secs)s"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CoachingView(report: MeetingCoachReport(
            meetingDuration: 1800,
            speakerMetrics: [
                SpeakerCoachMetrics(
                    speaker: "You",
                    fillerWordCount: 12,
                    fillerBreakdown: ["um": 5, "like": 4, "you know": 3],
                    talkRatioPercent: 62,
                    wordsPerMinute: 155,
                    longestMonologueSeconds: 95,
                    questionCount: 4,
                    interruptionCount: 1,
                    totalSpeakingSeconds: 1116,
                    totalWords: 2882
                ),
                SpeakerCoachMetrics(
                    speaker: "Speaker 2",
                    fillerWordCount: 3,
                    fillerBreakdown: ["so": 2, "right": 1],
                    talkRatioPercent: 38,
                    wordsPerMinute: 140,
                    longestMonologueSeconds: 60,
                    questionCount: 6,
                    interruptionCount: 0,
                    totalSpeakingSeconds: 684,
                    totalWords: 1596
                )
            ],
            totalFillerWords: 15,
            totalQuestions: 10,
            totalInterruptions: 1,
            generatedAt: Date()
        ))
    }
}
