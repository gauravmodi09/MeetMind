import SwiftUI

struct MeetingDetailView: View {
    let meeting: Meeting

    @Environment(\.dismiss) private var dismiss
    @State private var showTranscript = false
    @State private var copiedBrief = false
    @State private var copiedNotion = false
    @State private var isRegenerating = false
    @State private var completedItems: Set<UUID> = []
    @State private var showShareSheet = false
    @State private var showFollowUpEmail = false
    @State private var showMeetingChat = false
    @State private var showCoaching = false
    @State private var sectionsAppeared = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Failed state — retry banner
                    if meeting.status == .failed {
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(MMColors.recording)
                                Text("Processing failed")
                                    .font(MMTypography.bodyMedium)
                                    .foregroundColor(MMColors.recording)
                                Spacer()
                            }

                            Button {
                                Task { await MeetingService.shared.reprocessMeeting(meeting) }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Retry Processing")
                                }
                                .font(MMTypography.footnoteMedium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(MMColors.primary)
                                .cornerRadius(12)
                            }
                        }
                        .padding(16)
                        .background(MMColors.recording.opacity(0.08))
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    }

                    // Header meta
                    headerSection
                        .opacity(sectionsAppeared ? 1 : 0)
                        .offset(y: sectionsAppeared ? 0 : 16)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.0), value: sectionsAppeared)

                    // Summary Card
                    if let summary = meeting.briefSummary, let tldr = extractTLDR(from: summary) {
                        tldrCard(tldr)
                            .opacity(sectionsAppeared ? 1 : 0)
                            .offset(y: sectionsAppeared ? 0 : 16)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: sectionsAppeared)
                    }

                    // Summary
                    if let summary = meeting.briefSummary, !summary.isEmpty {
                        summarySection(summary)
                            .opacity(sectionsAppeared ? 1 : 0)
                            .offset(y: sectionsAppeared ? 0 : 16)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: sectionsAppeared)
                    }

                    // Enhanced Notes
                    if let enhancedNotes = meeting.enhancedNotes, !enhancedNotes.isEmpty {
                        EnhancedNotesView(
                            blocks: enhancedNotes,
                            onReEnhance: {
                                Task {
                                    await MeetingService.shared.enhanceNotes(for: meeting)
                                }
                            }
                        )
                        .padding(.horizontal, 16)
                        .opacity(sectionsAppeared ? 1 : 0)
                        .offset(y: sectionsAppeared ? 0 : 16)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: sectionsAppeared)
                    }

                    // Decisions
                    if !meeting.briefDecisions.isEmpty {
                        decisionsSection
                            .opacity(sectionsAppeared ? 1 : 0)
                            .offset(y: sectionsAppeared ? 0 : 16)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: sectionsAppeared)
                    }

                    // Action Items
                    if !meeting.briefActionItems.isEmpty {
                        actionItemsSection
                            .opacity(sectionsAppeared ? 1 : 0)
                            .offset(y: sectionsAppeared ? 0 : 16)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: sectionsAppeared)
                    }

                    // Open Questions
                    if let summary = meeting.briefSummary {
                        let questions = extractOpenQuestions(from: summary)
                        if !questions.isEmpty {
                            openQuestionsSection(questions)
                                .opacity(sectionsAppeared ? 1 : 0)
                                .offset(y: sectionsAppeared ? 0 : 16)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35), value: sectionsAppeared)
                        }
                    }

                    // Key Quotes
                    if !meeting.briefKeyQuotes.isEmpty {
                        keyQuotesSection
                            .opacity(sectionsAppeared ? 1 : 0)
                            .offset(y: sectionsAppeared ? 0 : 16)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: sectionsAppeared)
                    }

                    // Key Topics
                    if !meeting.briefKeyTopics.isEmpty {
                        keyTopicsSection
                            .opacity(sectionsAppeared ? 1 : 0)
                            .offset(y: sectionsAppeared ? 0 : 16)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: sectionsAppeared)
                    }

                    // Transcript
                    if let transcript = meeting.rawTranscript, !transcript.isEmpty {
                        transcriptSection(transcript)
                            .opacity(sectionsAppeared ? 1 : 0)
                            .offset(y: sectionsAppeared ? 0 : 16)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.6), value: sectionsAppeared)
                    }

                    // Audio Highlights (Key Moments)
                    if let transcript = meeting.rawTranscript, !transcript.isEmpty {
                        let segments = parseTranscriptToSegments(transcript)
                        let highlights = HighlightExtractionService.extractHighlights(transcript: transcript, segments: segments)
                        if !highlights.isEmpty {
                            AudioHighlightsView(highlights: highlights)
                                .padding(.horizontal, 16)
                        }
                    }

                    // AI Chat + Follow-up buttons
                    if meeting.status == .complete {
                        VStack(spacing: 10) {
                            MMButton("Ask AI about this meeting", icon: "bubble.left.and.bubble.right") {
                                showMeetingChat = true
                            }

                            MMButton("Write Follow-up", icon: "envelope", style: .secondary) {
                                showFollowUpEmail = true
                            }

                            MMButton("Communication Coach", icon: "figure.mind.and.body", style: .secondary) {
                                showCoaching = true
                            }

                            MMButton("Email Notes", icon: "envelope.fill", style: .secondary) {
                                emailMeetingNotes()
                            }

                            MMButton(copiedNotion ? "Copied for Notion!" : "Copy for Notion", icon: "doc.on.clipboard", style: .ghost) {
                                copyForNotion()
                            }

                            if !(UserDefaults.standard.string(forKey: "teamsWebhookURL") ?? "").isEmpty {
                                MMButton("Send to Teams", icon: "paperplane.fill", style: .secondary) {
                                    Task {
                                        let items = meeting.briefActionItems.map { "\($0.text) (\($0.owner))" }
                                        await TeamsIntegrationService.shared.sendToTeams(
                                            title: meeting.title,
                                            summary: meeting.briefSummary ?? "",
                                            actionItems: items,
                                            webhookURL: UserDefaults.standard.string(forKey: "teamsWebhookURL") ?? ""
                                        )
                                    }
                                }
                            }

                            // Regenerate notes with latest AI prompt
                            if meeting.rawTranscript != nil && !isRegenerating {
                                MMButton("Regenerate Notes", icon: "arrow.clockwise", style: .ghost) {
                                    isRegenerating = true
                                    Task {
                                        await MeetingService.shared.regenerateNotes(meeting)
                                        isRegenerating = false
                                    }
                                }
                            }
                            if isRegenerating {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .tint(MMColors.primary)
                                    Text("Regenerating notes with latest AI...")
                                        .font(MMTypography.caption1)
                                        .foregroundColor(MMColors.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Bottom spacing for sticky bar
                    Color.clear.frame(height: audioFileURL != nil ? 120 : 80)
                }
            }

            // Sticky action bar at bottom
            stickyActionBar
        }
        .safeAreaInset(edge: .bottom) {
            if let audioURL = audioFileURL {
                AudioPlayerView(audioURL: audioURL)
            }
        }
        .background(MMColors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(MMTypography.subheadline)
                    }
                    .foregroundColor(MMColors.primary)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showMeetingChat) {
            MeetingChatSheet(meeting: meeting)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showFollowUpEmail) {
            FollowUpEmailView(meeting: meeting)
        }
        .sheet(isPresented: $showCoaching) {
            NavigationStack {
                if let transcript = meeting.rawTranscript {
                    let segments = parseTranscriptToSegments(transcript)
                    let report = MeetingCoachService.shared.analyze(segments: segments)
                    CoachingView(report: report)
                }
            }
        }
        .onAppear {
            withAnimation {
                sectionsAppeared = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Hero title
            Text(meeting.title)
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundColor(MMColors.textPrimary)
                .lineSpacing(2)

            // Metadata row with richer styling
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MMColors.primary)
                    Text(formattedDate)
                        .font(MMTypography.footnote)
                        .foregroundColor(MMColors.textSecondary)
                }

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MMColors.primary)
                    Text(formattedDuration)
                        .font(MMTypography.footnote)
                        .foregroundColor(MMColors.textSecondary)
                }

                if !meeting.briefActionItems.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "checklist")
                            .font(.system(size: 10, weight: .semibold))
                        Text("\(meeting.briefActionItems.count) actions")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(MMColors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(MMColors.primaryLight)
                    .clipShape(Capsule())
                }

                if let client = meeting.clientName {
                    MMBadge(text: client, variant: .client(clientColorHex))
                }
            }

            // Key topics as horizontal scrolling pills
            if !meeting.briefKeyTopics.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(meeting.briefKeyTopics, id: \.self) { topic in
                            Text(topic)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(MMColors.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(MMColors.glass)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(MMColors.glassStroke, lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Sticky Action Bar

    private var stickyActionBar: some View {
        HStack(spacing: 16) {
            Button {
                copyBrief()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: copiedBrief ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 14, weight: .semibold))
                    Text(copiedBrief ? "Copied!" : "Copy Brief")
                        .font(MMTypography.footnoteMedium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(copiedBrief ? MMColors.success : MMColors.primary)
                .cornerRadius(12)
                .animation(.easeInOut(duration: 0.2), value: copiedBrief)
            }
            .accessibilityLabel(copiedBrief ? "Brief copied to clipboard" : "Copy brief")
            .accessibilityHint("Double-tap to copy the meeting brief to your clipboard")

            Button {
                shareBrief()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Share")
                        .font(MMTypography.footnoteMedium)
                }
                .foregroundColor(MMColors.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(MMColors.primaryLight)
                .cornerRadius(12)
            }
            .accessibilityLabel("Share brief")
            .accessibilityHint("Double-tap to share the meeting brief")

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            .ultraThinMaterial
        )
        .overlay(
            Rectangle()
                .fill(MMColors.border)
                .frame(height: 1),
            alignment: .top
        )
    }

    // MARK: - Summary Section

    private func summarySection(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Meeting Intelligence", icon: "brain")

            HStack(spacing: 0) {
                // Purple tinted left border
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [MMColors.primary, MMColors.primary.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3)

                // Rich formatted summary with bold headings
                richSummaryText(summary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(MMColors.cardBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(MMColors.border, lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Summary Card

    private func tldrCard(_ tldr: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MMColors.warning)

                Text("Executive Summary")
                    .font(MMTypography.headline)
                    .foregroundColor(MMColors.warning)
            }

            renderBoldText(tldr)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MMColors.warning.opacity(0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MMColors.warning.opacity(0.3), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(MMColors.warning)
                .frame(width: 3)
                .padding(.vertical, 8)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Open Questions Section

    private func openQuestionsSection(_ questions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Open Questions", icon: "questionmark.circle")

            VStack(spacing: 8) {
                ForEach(Array(questions.enumerated()), id: \.offset) { _, question in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(MMColors.info)
                            .padding(.top, 2)

                        renderBoldText(question)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(MMColors.info.opacity(0.06))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(MMColors.info.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Extract Summary

    private func extractTLDR(from summary: String) -> String? {
        let lines = summary.components(separatedBy: "\n")
        var capturing = false
        var result = ""
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Match any of: ## Summary, ## Executive Summary, ## TL;DR, ## TLDR, ## Meeting Overview
            if trimmed.hasPrefix("## Executive Summary") ||
               trimmed.hasPrefix("## Summary") ||
               trimmed.hasPrefix("## TL;DR") ||
               trimmed.hasPrefix("## TLDR") {
                capturing = true
                continue
            }
            if capturing && trimmed.hasPrefix("##") { break }
            if capturing && !trimmed.isEmpty && !trimmed.hasPrefix("#") && !trimmed.hasPrefix("---") {
                result += (result.isEmpty ? "" : " ") + trimmed
            }
        }
        // Limit to first ~500 chars for the summary card (keep it scannable)
        if result.count > 500 {
            let index = result.index(result.startIndex, offsetBy: 500)
            if let spaceIndex = result[...index].lastIndex(of: " ") {
                result = String(result[...spaceIndex]) + "..."
            }
        }
        return result.isEmpty ? nil : result
    }

    // MARK: - Extract Open Questions

    private func extractOpenQuestions(from summary: String) -> [String] {
        let lines = summary.components(separatedBy: "\n")
        var capturing = false
        var questions: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("## Open Questions") {
                capturing = true
                continue
            }
            if capturing && trimmed.hasPrefix("##") { break }
            if capturing && (trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ")) {
                questions.append(String(trimmed.dropFirst(2)))
            }
        }
        return questions
    }

    /// Renders the summary with markdown-style formatting (##, ###, **bold**, bullets, numbered lists)
    private func richSummaryText(_ summary: String) -> some View {
        let lines = summary.components(separatedBy: "\n")

        return VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                if trimmed.isEmpty {
                    Spacer().frame(height: 8)
                } else if trimmed.hasPrefix("# ") && !trimmed.hasPrefix("## ") {
                    // # Title — skip it, already shown as meeting.title
                    EmptyView()
                } else if trimmed.hasPrefix("### ") {
                    // ### Sub-heading
                    Text(trimmed.replacingOccurrences(of: "### ", with: ""))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(MMColors.textPrimary)
                        .padding(.top, 8)
                        .padding(.bottom, 2)
                } else if trimmed.hasPrefix("## ") {
                    // ## Section heading — purple accent
                    Text(trimmed.replacingOccurrences(of: "## ", with: ""))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(MMColors.primary)
                        .padding(.top, 14)
                        .padding(.bottom, 4)
                } else if isHeading(trimmed) {
                    // ALL CAPS fallback for older/custom prompts
                    Text(trimmed)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(MMColors.primary)
                        .padding(.top, 14)
                        .padding(.bottom, 4)
                } else if trimmed.hasPrefix("• ") || trimmed.hasPrefix("- ") {
                    // Bullet point
                    let bulletText = trimmed.hasPrefix("• ") ? String(trimmed.dropFirst(2)) : String(trimmed.dropFirst(2))
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(MMColors.primary.opacity(0.5))
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        renderBoldText(bulletText)
                    }
                } else if trimmed.first?.isNumber == true && trimmed.contains(". ") {
                    // Numbered list item
                    let parts = trimmed.split(separator: ".", maxSplits: 1)
                    HStack(alignment: .top, spacing: 8) {
                        Text(String(parts[0]) + ".")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(MMColors.primary)
                            .frame(width: 22, alignment: .trailing)
                        if parts.count > 1 {
                            renderBoldText(String(parts[1]).trimmingCharacters(in: .whitespaces))
                        }
                    }
                } else if trimmed.hasPrefix("|") && trimmed.hasSuffix("|") {
                    // Markdown table — convert rows to clean bullet points
                    if trimmed.contains("---") {
                        // Skip separator line
                        EmptyView()
                    } else {
                        let cells = trimmed.split(separator: "|").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                        let isHeader = cells.contains(where: { ["Task", "Owner", "Due", "Priority", "Date"].contains($0) })
                        if !isHeader && cells.count >= 2 {
                            // Render as a clean bullet point: Task → Owner, Due, Priority
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(MMColors.primary.opacity(0.5))
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 7)
                                VStack(alignment: .leading, spacing: 3) {
                                    renderBoldText(cells[0])
                                    let meta = cells.dropFirst().filter { !$0.isEmpty }.map { $0.replacingOccurrences(of: "**", with: "") }.joined(separator: " · ")
                                    if !meta.isEmpty {
                                        Text(meta)
                                            .font(.system(size: 12))
                                            .foregroundColor(MMColors.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // Normal paragraph text with **bold** support
                    renderBoldText(trimmed)
                }
            }
        }
    }

    /// Renders text with **bold** markdown segments
    private func renderBoldText(_ text: String) -> some View {
        let attributed = parseBoldSegments(text)
        return Text(attributed)
            .font(MMTypography.body)
            .foregroundColor(MMColors.textPrimary)
            .lineSpacing(4)
    }

    /// Parses **bold** markers into an AttributedString
    private func parseBoldSegments(_ text: String) -> AttributedString {
        var result = AttributedString()
        var remaining = text

        while let startRange = remaining.range(of: "**") {
            // Add text before the bold marker
            let before = String(remaining[remaining.startIndex..<startRange.lowerBound])
            if !before.isEmpty {
                result.append(AttributedString(before))
            }

            // Find closing **
            let afterStart = remaining[startRange.upperBound...]
            if let endRange = afterStart.range(of: "**") {
                let boldContent = String(afterStart[afterStart.startIndex..<endRange.lowerBound])
                var boldAttr = AttributedString(boldContent)
                boldAttr.font = .system(size: 15, weight: .bold)
                result.append(boldAttr)
                remaining = String(afterStart[endRange.upperBound...])
            } else {
                // No closing **, just add the rest as-is
                result.append(AttributedString(String(remaining[startRange.lowerBound...])))
                remaining = ""
            }
        }

        // Add any remaining text
        if !remaining.isEmpty {
            result.append(AttributedString(remaining))
        }

        return result
    }

    /// Check if a line is an ALL CAPS heading (fallback for plain-text prompts)
    private func isHeading(_ line: String) -> Bool {
        let stripped = line.trimmingCharacters(in: .whitespaces)
        guard stripped.count >= 3, stripped.count <= 60 else { return false }
        let allowed = CharacterSet.uppercaseLetters.union(.whitespaces).union(CharacterSet(charactersIn: "&/-"))
        return stripped.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    // MARK: - Decisions Section

    private var decisionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Decisions", icon: "checkmark.seal")

            VStack(spacing: 8) {
                ForEach(meeting.briefDecisions, id: \.self) { decision in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(MMColors.success)
                            .padding(.top, 2)

                        Text(decision)
                            .font(MMTypography.body)
                            .foregroundColor(MMColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(MMColors.cardBg)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(MMColors.border, lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Action Items Section

    private var actionItemsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Action Items", icon: "checklist")

            VStack(spacing: 8) {
                ForEach(meeting.briefActionItems) { item in
                    actionItemCard(item)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func actionItemCard(_ item: ActionItem) -> some View {
        let isComplete = completedItems.contains(item.id)
        let priorityColor: Color = item.isMine ? MMColors.warning : MMColors.primary

        return HStack(spacing: 0) {
            // Priority-colored left bar
            Rectangle()
                .fill(priorityColor)
                .frame(width: 3)

            HStack(alignment: .top, spacing: 16) {
                // Checkbox
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isComplete {
                            completedItems.remove(item.id)
                        } else {
                            completedItems.insert(item.id)
                        }
                    }
                } label: {
                    Circle()
                        .fill(
                            isComplete ? MMColors.success :
                            item.isMine ? MMColors.warning.opacity(0.2) :
                            MMColors.border
                        )
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(
                                    isComplete ? MMColors.success :
                                    item.isMine ? MMColors.warning :
                                    MMColors.textTertiary,
                                    lineWidth: 2
                                )
                        )
                        .overlay(
                            isComplete ?
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                            : nil
                        )
                }
                .accessibilityLabel(isComplete ? "Mark action item incomplete" : "Mark action item complete")
                .accessibilityValue(isComplete ? "Completed" : "Pending")

                VStack(alignment: .leading, spacing: 8) {
                    Text(item.text)
                        .font(MMTypography.body)
                        .foregroundColor(isComplete ? MMColors.textTertiary : MMColors.textPrimary)
                        .strikethrough(isComplete)

                    HStack(spacing: 8) {
                        if !item.owner.isEmpty {
                            Text(item.owner)
                                .font(MMTypography.caption1)
                                .foregroundColor(MMColors.textSecondary)
                        }

                        if let due = item.dueDate {
                            Text("Due: \(formattedShortDate(due))")
                                .font(MMTypography.caption1)
                                .foregroundColor(MMColors.warning)
                        }

                        Text("from meeting")
                            .font(MMTypography.caption2)
                            .foregroundColor(MMColors.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(MMColors.background)
                            .cornerRadius(4)
                    }
                }

                Spacer()
            }
            .padding(16)
        }
        .background(MMColors.cardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MMColors.border, lineWidth: 1)
        )
    }

    // MARK: - Key Quotes Section

    private var keyQuotesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Key Quotes", icon: "quote.opening")

            VStack(spacing: 8) {
                ForEach(Array(meeting.briefKeyQuotes.prefix(3).enumerated()), id: \.offset) { _, quote in
                    keyQuoteCard(quote)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func keyQuoteCard(_ quote: String) -> some View {
        let parts = parseQuote(quote)

        return HStack(alignment: .top, spacing: 12) {
            // Quote icon — uses a warm amber to stand out
            Image(systemName: "quote.opening")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(MMColors.warning)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                // Speaker name — bold, high contrast
                if let speaker = parts.speaker {
                    Text(speaker)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(MMColors.textPrimary)
                }

                // Quote text — italic, dark and readable (not light blue)
                Text("\u{201C}\(parts.text)\u{201D}")
                    .font(.system(size: 15, weight: .medium))
                    .italic()
                    .foregroundColor(MMColors.textPrimary.opacity(0.85))
                    .lineSpacing(5)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            // Warm, visible background instead of plain card
            MMColors.warning.opacity(0.06)
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MMColors.warning.opacity(0.25), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            // Amber accent bar on left for visibility
            RoundedRectangle(cornerRadius: 2)
                .fill(MMColors.warning)
                .frame(width: 3)
                .padding(.vertical, 8)
        }
    }

    private func parseQuote(_ quote: String) -> (speaker: String?, text: String) {
        if let colonRange = quote.range(of: ": ", options: [], range: quote.startIndex..<quote.index(quote.startIndex, offsetBy: min(40, quote.count))) {
            let speaker = String(quote[quote.startIndex..<colonRange.lowerBound])
            let text = String(quote[colonRange.upperBound...])
            return (speaker, text)
        }
        return (nil, quote)
    }

    // MARK: - Key Topics Section

    private var keyTopicsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Key Topics", icon: "tag")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(meeting.briefKeyTopics, id: \.self) { topic in
                        Text(topic)
                            .font(MMTypography.footnoteMedium)
                            .foregroundColor(MMColors.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(MMColors.primaryLight)
                            .cornerRadius(20)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Transcript Section

    private func transcriptSection(_ transcript: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showTranscript.toggle()
                }
            } label: {
                HStack {
                    sectionTitle("Transcript", icon: "doc.plaintext")

                    Spacer()

                    Image(systemName: showTranscript ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MMColors.textTertiary)
                }
            }
            .accessibilityLabel("Transcript section")
            .accessibilityValue(showTranscript ? "Expanded" : "Collapsed")
            .accessibilityHint("Double-tap to \(showTranscript ? "collapse" : "expand") the transcript")

            if showTranscript {
                TranscriptTextView(transcript: transcript)
                    .padding(16)
                    .background(MMColors.cardBg)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(MMColors.border, lineWidth: 1)
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Section Title Helper

    private func sectionTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(MMColors.primary)

            Text(title)
                .font(MMTypography.headline)
                .foregroundColor(MMColors.textPrimary)
        }
    }

    // MARK: - Audio File

    private var audioFileURL: URL? {
        guard let path = meeting.audioFilePath, !path.isEmpty else { return nil }
        let fullPathURL = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: fullPathURL.path) {
            return fullPathURL
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let docsURL = docs.appendingPathComponent(fullPathURL.lastPathComponent)
        if FileManager.default.fileExists(atPath: docsURL.path) {
            return docsURL
        }
        return nil
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: meeting.date)
    }

    private var formattedDuration: String {
        let minutes = Int(meeting.duration) / 60
        if minutes < 60 {
            return "\(minutes) min"
        }
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    private func formattedShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private var clientColorHex: String {
        guard let name = meeting.clientName else { return "6C5CE7" }
        let colors = ["6C5CE7", "FF4757", "00CE9E", "FFA502", "2D98FF", "E84393", "00B894", "FDCB6E"]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }

    private func parseTranscriptToSegments(_ text: String) -> [TranscriptSegment] {
        let sentences = text.components(separatedBy: ". ")
        var segments: [TranscriptSegment] = []
        var time: Double = 0
        for sentence in sentences {
            let duration = Double(sentence.count) / 20.0 // rough estimate
            segments.append(TranscriptSegment(start: time, end: time + duration, text: sentence))
            time += duration + 0.5
        }
        return segments
    }

    private func copyBrief() {
        let brief = MeetingBriefFormatter.format(meeting: meeting)
        UIPasteboard.general.string = brief
        copiedBrief = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedBrief = false
        }
    }

    private func shareBrief() {
        showShareSheet = true
    }

    private func emailMeetingNotes() {
        let subject = meeting.title
        var body = MeetingBriefFormatter.format(meeting: meeting)
        body = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:?subject=\(encodedSubject)&body=\(body)") {
            UIApplication.shared.open(url)
        }
    }

    private func copyForNotion() {
        var text = "# \(meeting.title)\n\n"
        text += "**Date:** \(formattedDate) | **Duration:** \(formattedDuration)\n"
        if let client = meeting.clientName { text += "**Client:** \(client)\n" }
        text += "\n---\n\n"

        if let summary = meeting.briefSummary {
            text += summary + "\n\n"
        }

        if !meeting.briefDecisions.isEmpty {
            text += "## Decisions\n\n"
            for d in meeting.briefDecisions { text += "- \(d)\n" }
            text += "\n"
        }

        if !meeting.briefActionItems.isEmpty {
            text += "## Action Items\n\n"
            for item in meeting.briefActionItems {
                let checkbox = item.isMine ? "- [ ] **\(item.text)** → \(item.owner) 🔴" : "- [ ] \(item.text) → \(item.owner)"
                text += "\(checkbox)\n"
            }
            text += "\n"
        }

        UIPasteboard.general.string = text
        copiedNotion = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedNotion = false
        }
    }

    private var shareItems: [Any] {
        var text = "\u{1F4CB} \(meeting.title)\n"
        text += "\u{1F4C5} \(formattedDate) \u{00B7} \(formattedDuration)\n\n"

        if let summary = meeting.briefSummary {
            if let tldr = extractTLDR(from: summary) {
                text += "Summary: \(tldr)\n\n"
            }
        }

        if !meeting.briefDecisions.isEmpty {
            text += "Key Decisions:\n"
            for d in meeting.briefDecisions { text += "\u{2022} \(d)\n" }
            text += "\n"
        }

        if !meeting.briefActionItems.isEmpty {
            text += "Action Items:\n"
            for item in meeting.briefActionItems {
                let mine = item.isMine ? " [YOU]" : ""
                text += "\u{2022} \(item.text) \u{2192} \(item.owner)\(mine)\n"
            }
            text += "\n"
        }

        text += "\u{2014} Shared from MeetMind"

        let textFileItem = MeetingBriefTextFileItem(
            briefText: text,
            meetingTitle: meeting.title
        )
        return [textFileItem]
    }
}

// MARK: - Transcript Text View

struct TranscriptTextView: View {
    let transcript: String

    var body: some View {
        let parts = parseTranscript(transcript)

        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                if part.isUnclear {
                    Text(part.text)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundColor(MMColors.warning)
                        .italic()
                        .padding(.horizontal, 4)
                        .background(MMColors.warningLight)
                        .cornerRadius(3)
                        .accessibilityLabel("Unclear speech segment")
                } else {
                    Text(part.text)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundColor(MMColors.textSecondary)
                        .lineSpacing(6)
                }
            }
        }
    }

    private struct TranscriptPart {
        let text: String
        let isUnclear: Bool
    }

    private func parseTranscript(_ text: String) -> [TranscriptPart] {
        var parts: [TranscriptPart] = []
        var remaining = text

        while let unclearStart = remaining.range(of: "[unclear]") {
            let before = String(remaining[remaining.startIndex..<unclearStart.lowerBound])
            if !before.isEmpty {
                parts.append(TranscriptPart(text: before, isUnclear: false))
            }
            parts.append(TranscriptPart(text: "[unclear]", isUnclear: true))
            remaining = String(remaining[unclearStart.upperBound...])
        }

        if !remaining.isEmpty {
            parts.append(TranscriptPart(text: remaining, isUnclear: false))
        }

        return parts
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MeetingDetailView(
            meeting: Meeting(
                title: "Weekly Sync with Acme Corp",
                date: Date(),
                duration: 1800,
                clientName: "Acme Corp",
                status: .complete,
                briefSummary: "Discussed Q3 revenue targets and agreed to accelerate the product roadmap. The team will focus on mobile-first features for the next sprint. Budget approval is pending from finance.",
                briefDecisions: [
                    "Move to bi-weekly sprint cycles starting next month",
                    "Allocate 20% of budget to mobile development",
                    "Postpone enterprise features to Q4"
                ],
                briefActionItems: [
                    ActionItem(text: "Send updated proposal with revised timeline", owner: "Me", dueDate: Date().addingTimeInterval(86400 * 3), isMine: true),
                    ActionItem(text: "Review contract terms with legal", owner: "Sarah", dueDate: Date().addingTimeInterval(86400 * 5)),
                    ActionItem(text: "Prepare demo for stakeholder review", owner: "Me", dueDate: Date().addingTimeInterval(86400 * 7), isMine: true)
                ],
                briefKeyTopics: ["Q3 Targets", "Product Roadmap", "Mobile Strategy", "Budget", "Sprint Planning"],
                rawTranscript: "So looking at Q3 targets, I think we need to be more aggressive on the mobile side. [unclear] The data shows that 68% of our users are now on mobile. Sarah, can you take a look at the contract terms? We should have that ready by Friday. [unclear] And let's plan a demo for the stakeholders next week."
            )
        )
    }
}
