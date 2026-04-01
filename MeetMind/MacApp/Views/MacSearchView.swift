#if os(macOS)
import SwiftUI

// MARK: - Mac Search Result Types

enum MacSearchCategory: String, CaseIterable, Identifiable {
    case meetings    = "Meetings"
    case actionItems = "Action Items"
    case decisions   = "Decisions"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .meetings:    return "doc.text"
        case .actionItems: return "checklist"
        case .decisions:   return "checkmark.seal"
        }
    }
}

struct MacSearchResult: Identifiable {
    let id = UUID()
    let category: MacSearchCategory
    let title: String
    let snippet: String
    let meetingId: UUID
    let meetingTitle: String
    let meetingDate: Date
    let meetingClient: String?
    let meetingTemplate: MeetingTemplate
    let relevanceScore: Int  // higher = more relevant
}

// MARK: - MacSearchView

struct MacSearchView: View {
    @EnvironmentObject var meetingService: MeetingService

    @State private var searchText: String = ""
    @State private var selectedCategory: MacSearchCategory = .meetings
    @State private var results: [MacSearchCategory: [MacSearchResult]] = [:]
    @State private var selectedResultId: UUID?
    @State private var selectedMeeting: Meeting?
    @FocusState private var isSearchFocused: Bool

    @AppStorage("recentMacSearches") private var recentSearchesData: Data = Data()

    private var recentSearches: [String] {
        (try? JSONDecoder().decode([String].self, from: recentSearchesData)) ?? []
    }

    private let suggestionChips: [String] = [
        "What did we decide about...",
        "Action items from...",
        "Meetings with...",
        "Follow-up on...",
        "Budget discussion",
        "Next steps",
        "Key topics from...",
        "Blockers mentioned"
    ]

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            // Left panel: search input + results list
            VStack(spacing: 0) {
                headerSection
                searchBarSection
                Divider()
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    idleContent
                } else if allResults.isEmpty {
                    noResultsView
                } else {
                    categoryTabBar
                    resultsList
                }
            }
            .frame(width: 340)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Right panel: meeting detail or placeholder
            if let meeting = selectedMeeting {
                MacSearchDetailPanel(meeting: meeting, highlightQuery: searchText)
                    .environmentObject(meetingService)
            } else {
                detailPlaceholder
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFocused = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Search")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(MMColors.textPrimary)
            Text("Find anything across your meetings")
                .font(.system(size: 12))
                .foregroundColor(MMColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    // MARK: - Search Bar

    private var searchBarSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSearchFocused ? MMColors.primary : MMColors.textTertiary)

            TextField("Search meetings, decisions, action items...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($isSearchFocused)
                .onSubmit {
                    saveRecentSearch(searchText)
                }
                .onChange(of: searchText) { _, newValue in
                    performSearch(query: newValue)
                    if !newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                        selectedCategory = .meetings
                        selectedMeeting = nil
                        selectedResultId = nil
                    }
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    results = [:]
                    selectedMeeting = nil
                    selectedResultId = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(MMColors.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(MMColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isSearchFocused ? MMColors.primary.opacity(0.6) : MMColors.border,
                            lineWidth: isSearchFocused ? 1.5 : 1
                        )
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
        .animation(.easeInOut(duration: 0.15), value: isSearchFocused)
    }

    // MARK: - Idle Content (Recents + Suggestions)

    private var idleContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {

                // Recent searches
                if !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recent Searches")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(MMColors.textTertiary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            Spacer()
                            Button("Clear") {
                                clearRecentSearches()
                            }
                            .font(.system(size: 11))
                            .foregroundColor(MMColors.textTertiary)
                            .buttonStyle(.plain)
                        }

                        ForEach(recentSearches, id: \.self) { query in
                            Button {
                                searchText = query
                                performSearch(query: query)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 11))
                                        .foregroundColor(MMColors.textTertiary)
                                    Text(query)
                                        .font(.system(size: 13))
                                        .foregroundColor(MMColors.textPrimary)
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .font(.system(size: 10))
                                        .foregroundColor(MMColors.textTertiary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.clear)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Suggestion chips
                VStack(alignment: .leading, spacing: 10) {
                    Text("Try searching")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(MMColors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    MacFlowLayout(spacing: 6) {
                        ForEach(suggestionChips, id: \.self) { chip in
                            Button {
                                searchText = chip
                                performSearch(query: chip)
                                isSearchFocused = true
                            } label: {
                                Text(chip)
                                    .font(.system(size: 12))
                                    .foregroundColor(MMColors.primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(MMColors.primaryLight)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Category Tab Bar

    private var categoryTabBar: some View {
        HStack(spacing: 0) {
            ForEach(MacSearchCategory.allCases) { category in
                let count = results[category]?.count ?? 0
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedCategory = category
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: category.icon)
                            .font(.system(size: 11))
                        Text(category.rawValue)
                            .font(.system(size: 12, weight: selectedCategory == category ? .semibold : .regular))
                        if count > 0 {
                            Text("\(count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(selectedCategory == category ? .white : MMColors.textTertiary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(
                                    Capsule()
                                        .fill(selectedCategory == category ? MMColors.primary : MMColors.border)
                                )
                        }
                    }
                    .foregroundColor(selectedCategory == category ? MMColors.primary : MMColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        VStack {
                            Spacer()
                            if selectedCategory == category {
                                Rectangle()
                                    .fill(MMColors.primary)
                                    .frame(height: 2)
                                    .cornerRadius(1)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        let categoryResults = results[selectedCategory] ?? []

        return ScrollView {
            if categoryResults.isEmpty {
                emptyCategoryView
            } else {
                LazyVStack(spacing: 2) {
                    ForEach(categoryResults) { result in
                        resultRow(result)
                            .padding(.horizontal, 12)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func resultRow(_ result: MacSearchResult) -> some View {
        let isSelected = selectedResultId == result.id

        return Button {
            selectedResultId = result.id
            saveRecentSearch(searchText)
            if let meeting = meetingService.meetings.first(where: { $0.id == result.meetingId }) {
                selectedMeeting = meeting
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    // Template icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(templateColor(result.meetingTemplate).opacity(0.12))
                            .frame(width: 28, height: 28)
                        Image(systemName: result.meetingTemplate.icon)
                            .font(.system(size: 11))
                            .foregroundColor(templateColor(result.meetingTemplate))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        // Title with highlight
                        highlightedText(result.title, query: searchText)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)

                        // Snippet
                        highlightedText(result.snippet, query: searchText)
                            .font(.system(size: 11))
                            .foregroundColor(MMColors.textTertiary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }

                // Meta row
                HStack(spacing: 6) {
                    // Template badge
                    Text(result.meetingTemplate.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(templateColor(result.meetingTemplate))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(templateColor(result.meetingTemplate).opacity(0.1))
                        )

                    if let client = result.meetingClient {
                        Text(client)
                            .font(.system(size: 10))
                            .foregroundColor(MMColors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    Text(formattedDate(result.meetingDate))
                        .font(.system(size: 10))
                        .foregroundColor(MMColors.textTertiary)
                }
                .padding(.leading, 36)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? MMColors.primary.opacity(0.08) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? MMColors.primary.opacity(0.25) : Color.clear, lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - No Results / Empty Category

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28))
                .foregroundColor(MMColors.textTertiary.opacity(0.5))
            Text("No results for \"\(searchText)\"")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(MMColors.textSecondary)
            Text("Try different keywords or check your spelling.")
                .font(.system(size: 11))
                .foregroundColor(MMColors.textTertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var emptyCategoryView: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: selectedCategory.icon)
                .font(.system(size: 24))
                .foregroundColor(MMColors.textTertiary.opacity(0.4))
            Text("No \(selectedCategory.rawValue.lowercased()) matched")
                .font(.system(size: 12))
                .foregroundColor(MMColors.textTertiary)
            Spacer()
        }
        .frame(minHeight: 120)
    }

    // MARK: - Detail Placeholder

    private var detailPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 44))
                .foregroundColor(MMColors.textTertiary.opacity(0.4))
            Text("Search your meetings")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(MMColors.textSecondary)
            Text("Results will appear here. Select a result to view the full meeting.")
                .font(.system(size: 12))
                .foregroundColor(MMColors.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MMColors.backgroundElevated)
    }

    // MARK: - Search Logic

    private var allResults: [MacSearchResult] {
        results.values.flatMap { $0 }
    }

    private func performSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = [:]
            return
        }
        let lower = trimmed.lowercased()

        var meetingResults: [MacSearchResult] = []
        var actionResults: [MacSearchResult]  = []
        var decisionResults: [MacSearchResult] = []

        for meeting in meetingService.meetings {
            let titleMatch    = meeting.title.localizedCaseInsensitiveContains(lower)
            let summaryMatch  = meeting.briefSummary?.localizedCaseInsensitiveContains(lower) ?? false
            let transcriptMatch = meeting.rawTranscript?.localizedCaseInsensitiveContains(lower) ?? false
            let clientMatch   = meeting.clientName?.localizedCaseInsensitiveContains(lower) ?? false
            let notesMatch    = meeting.userNotes?.localizedCaseInsensitiveContains(lower) ?? false
            let notepadMatch  = meeting.notepadContent?.localizedCaseInsensitiveContains(lower) ?? false
            let topicsMatch   = meeting.briefKeyTopics.contains { $0.localizedCaseInsensitiveContains(lower) }

            // Compute relevance
            var score = 0
            if titleMatch   { score += 100 }
            if summaryMatch { score += 60 }
            if clientMatch  { score += 50 }
            if topicsMatch  { score += 40 }
            if notesMatch   { score += 30 }
            if notepadMatch { score += 25 }
            if transcriptMatch { score += 10 }

            if score > 0 {
                let snippet: String
                if titleMatch {
                    snippet = meeting.briefSummary.flatMap { String($0.prefix(120)) } ?? "Meeting on \(formattedDate(meeting.date))"
                } else if summaryMatch, let summary = meeting.briefSummary {
                    snippet = extractSnippet(from: summary, around: lower)
                } else if clientMatch, let client = meeting.clientName {
                    snippet = "Client: \(client)"
                } else if topicsMatch {
                    let matched = meeting.briefKeyTopics.first { $0.localizedCaseInsensitiveContains(lower) } ?? ""
                    snippet = "Topic: \(matched)"
                } else if notesMatch, let notes = meeting.userNotes {
                    snippet = extractSnippet(from: notes, around: lower)
                } else if notepadMatch, let notepad = meeting.notepadContent {
                    snippet = extractSnippet(from: notepad, around: lower)
                } else if transcriptMatch, let transcript = meeting.rawTranscript {
                    snippet = extractSnippet(from: transcript, around: lower)
                } else {
                    snippet = meeting.briefSummary.flatMap { String($0.prefix(100)) } ?? ""
                }

                meetingResults.append(MacSearchResult(
                    category: .meetings,
                    title: meeting.title,
                    snippet: snippet,
                    meetingId: meeting.id,
                    meetingTitle: meeting.title,
                    meetingDate: meeting.date,
                    meetingClient: meeting.clientName,
                    meetingTemplate: meeting.template,
                    relevanceScore: score
                ))
            }

            // Action items
            for item in meeting.briefActionItems {
                if item.text.localizedCaseInsensitiveContains(lower) ||
                   item.owner.localizedCaseInsensitiveContains(lower) {
                    let ownerPart = item.owner.isEmpty ? "" : " — \(item.owner)"
                    actionResults.append(MacSearchResult(
                        category: .actionItems,
                        title: item.text,
                        snippet: "From: \(meeting.title)\(ownerPart)",
                        meetingId: meeting.id,
                        meetingTitle: meeting.title,
                        meetingDate: meeting.date,
                        meetingClient: meeting.clientName,
                        meetingTemplate: meeting.template,
                        relevanceScore: item.text.localizedCaseInsensitiveContains(lower) ? 80 : 40
                    ))
                }
            }

            // Decisions
            for decision in meeting.briefDecisions {
                if decision.localizedCaseInsensitiveContains(lower) {
                    decisionResults.append(MacSearchResult(
                        category: .decisions,
                        title: decision,
                        snippet: "Decided in: \(meeting.title)",
                        meetingId: meeting.id,
                        meetingTitle: meeting.title,
                        meetingDate: meeting.date,
                        meetingClient: meeting.clientName,
                        meetingTemplate: meeting.template,
                        relevanceScore: 70
                    ))
                }
            }
        }

        var grouped: [MacSearchCategory: [MacSearchResult]] = [:]
        if !meetingResults.isEmpty {
            grouped[.meetings] = meetingResults.sorted { $0.relevanceScore > $1.relevanceScore }
        }
        if !actionResults.isEmpty {
            grouped[.actionItems] = actionResults.sorted { $0.relevanceScore > $1.relevanceScore }
        }
        if !decisionResults.isEmpty {
            grouped[.decisions] = decisionResults
        }
        results = grouped

        // Auto-select category that has results (prioritise meetings)
        if grouped[selectedCategory] == nil || grouped[selectedCategory]?.isEmpty == true {
            if let first = MacSearchCategory.allCases.first(where: { grouped[$0] != nil && !(grouped[$0]!.isEmpty) }) {
                selectedCategory = first
            }
        }
    }

    // MARK: - Text Helpers

    private func highlightedText(_ text: String, query: String) -> Text {
        let queryLower = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !queryLower.isEmpty else {
            return Text(text).foregroundColor(MMColors.textPrimary)
        }
        let textLower = text.lowercased()
        guard let range = textLower.range(of: queryLower) else {
            return Text(text).foregroundColor(MMColors.textPrimary)
        }
        let before = String(text[text.startIndex..<range.lowerBound])
        let match  = String(text[range])
        let after  = String(text[range.upperBound...])
        return Text(before).foregroundColor(MMColors.textPrimary)
            + Text(match).bold().foregroundColor(MMColors.primary)
            + Text(after).foregroundColor(MMColors.textPrimary)
    }

    private func extractSnippet(from text: String, around query: String) -> String {
        guard let range = text.range(of: query, options: .caseInsensitive) else {
            return String(text.prefix(120))
        }
        let startDist = text.distance(from: text.startIndex, to: range.lowerBound)
        let snippetStart = text.index(range.lowerBound, offsetBy: -min(startDist, 40), limitedBy: text.startIndex) ?? text.startIndex
        let snippetEnd   = text.index(range.upperBound, offsetBy: 80, limitedBy: text.endIndex) ?? text.endIndex
        var snippet = String(text[snippetStart..<snippetEnd])
        if snippetStart != text.startIndex { snippet = "..." + snippet }
        if snippetEnd   != text.endIndex   { snippet += "..." }
        return snippet
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

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

    // MARK: - Recent Searches

    private func saveRecentSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var searches = recentSearches
        searches.removeAll { $0 == trimmed }
        searches.insert(trimmed, at: 0)
        searches = Array(searches.prefix(8))
        recentSearchesData = (try? JSONEncoder().encode(searches)) ?? Data()
    }

    private func clearRecentSearches() {
        recentSearchesData = (try? JSONEncoder().encode([String]())) ?? Data()
    }
}

// MARK: - MacSearchDetailPanel

struct MacSearchDetailPanel: View {
    @EnvironmentObject var meetingService: MeetingService
    let meeting: Meeting
    let highlightQuery: String

    @State private var selectedTab: DetailTab = .summary

    enum DetailTab: String, CaseIterable, Identifiable {
        case summary    = "Summary"
        case transcript = "Transcript"
        case notes      = "Notes"

        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Meeting header
            meetingHeader

            Divider()

            // Tab bar
            HStack(spacing: 0) {
                ForEach(DetailTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? MMColors.primary : MMColors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                VStack {
                                    Spacer()
                                    if selectedTab == tab {
                                        Rectangle()
                                            .fill(MMColors.primary)
                                            .frame(height: 2)
                                            .cornerRadius(1)
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .overlay(alignment: .bottom) { Divider() }

            // Tab content
            ScrollView {
                switch selectedTab {
                case .summary:
                    summaryContent
                case .transcript:
                    transcriptContent
                case .notes:
                    notesContent
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MMColors.backgroundElevated)
    }

    // MARK: - Meeting Header

    private var meetingHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(templateColor(meeting.template).opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: meeting.template.icon)
                    .font(.system(size: 16))
                    .foregroundColor(templateColor(meeting.template))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(meeting.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(MMColors.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(meeting.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11))
                        .foregroundColor(MMColors.textTertiary)

                    Text("·")
                        .foregroundColor(MMColors.textTertiary)
                        .font(.system(size: 11))

                    Text(formatDuration(meeting.duration))
                        .font(.system(size: 11))
                        .foregroundColor(MMColors.textTertiary)

                    if let client = meeting.clientName {
                        Text("·")
                            .foregroundColor(MMColors.textTertiary)
                            .font(.system(size: 11))
                        Text(client)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(MMColors.textSecondary)
                    }
                }

                // Template badge
                Text(meeting.template.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(templateColor(meeting.template))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(templateColor(meeting.template).opacity(0.1))
                    )
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    // MARK: - Summary Tab

    private var summaryContent: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Brief summary
            if let summary = meeting.briefSummary {
                detailSection(title: "Summary", icon: "doc.text") {
                    highlightedBodyText(summary)
                        .font(.system(size: 13))
                        .foregroundColor(MMColors.textSecondary)
                        .lineSpacing(3)
                }
            }

            // Key topics
            if !meeting.briefKeyTopics.isEmpty {
                detailSection(title: "Key Topics", icon: "tag") {
                    MacSearchFlowWrap(items: meeting.briefKeyTopics, query: highlightQuery)
                }
            }

            // Decisions
            if !meeting.briefDecisions.isEmpty {
                detailSection(title: "Decisions", icon: "checkmark.seal") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(meeting.briefDecisions.enumerated()), id: \.offset) { _, decision in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(MMColors.success)
                                    .padding(.top, 1)
                                highlightedBodyText(decision)
                                    .font(.system(size: 13))
                                    .foregroundColor(MMColors.textSecondary)
                            }
                        }
                    }
                }
            }

            // Action items
            if !meeting.briefActionItems.isEmpty {
                detailSection(title: "Action Items", icon: "checklist") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(meeting.briefActionItems) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(item.isCompleted ? MMColors.success : MMColors.textTertiary)
                                    .padding(.top, 1)
                                VStack(alignment: .leading, spacing: 2) {
                                    highlightedBodyText(item.text)
                                        .font(.system(size: 13))
                                        .foregroundColor(item.isCompleted ? MMColors.textTertiary : MMColors.textPrimary)
                                    if !item.owner.isEmpty {
                                        Text(item.owner)
                                            .font(.system(size: 11))
                                            .foregroundColor(MMColors.textTertiary)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
            }

            // Key quotes
            if !meeting.briefKeyQuotes.isEmpty {
                detailSection(title: "Key Quotes", icon: "quote.bubble") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(meeting.briefKeyQuotes.enumerated()), id: \.offset) { _, quote in
                            HStack(alignment: .top, spacing: 8) {
                                Rectangle()
                                    .fill(MMColors.primary)
                                    .frame(width: 3)
                                    .cornerRadius(2)
                                highlightedBodyText(quote)
                                    .font(.system(size: 12))
                                    .italic()
                                    .foregroundColor(MMColors.textSecondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // MARK: - Transcript Tab

    private var transcriptContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let transcript = meeting.rawTranscript, !transcript.isEmpty {
                highlightedBodyText(transcript)
                    .font(.system(size: 13))
                    .foregroundColor(MMColors.textSecondary)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
            } else {
                emptyTabView(icon: "waveform", message: "No transcript available for this meeting.")
            }
        }
    }

    // MARK: - Notes Tab

    private var notesContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let notes = meeting.userNotes, !notes.isEmpty {
                detailSection(title: "Meeting Notes", icon: "note.text") {
                    highlightedBodyText(notes)
                        .font(.system(size: 13))
                        .foregroundColor(MMColors.textSecondary)
                        .lineSpacing(3)
                }
            }

            if let notepad = meeting.notepadContent, !notepad.isEmpty {
                detailSection(title: "Notepad", icon: "pencil.line") {
                    highlightedBodyText(notepad)
                        .font(.system(size: 13))
                        .foregroundColor(MMColors.textSecondary)
                        .lineSpacing(3)
                }
            }

            if (meeting.userNotes ?? "").isEmpty && (meeting.notepadContent ?? "").isEmpty {
                emptyTabView(icon: "note.text", message: "No notes for this meeting.")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // MARK: - Section Builder

    private func detailSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(MMColors.primary)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MMColors.textPrimary)
                    .textCase(.uppercase)
                    .tracking(0.4)
            }
            content()
        }
    }

    private func emptyTabView(icon: String, message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(MMColors.textTertiary.opacity(0.4))
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(MMColors.textTertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .padding(.horizontal, 24)
    }

    // MARK: - Text Highlight

    private func highlightedBodyText(_ text: String) -> Text {
        let queryLower = highlightQuery.trimmingCharacters(in: .whitespaces).lowercased()
        guard !queryLower.isEmpty else {
            return Text(text)
        }
        let textLower = text.lowercased()
        guard let range = textLower.range(of: queryLower) else {
            return Text(text)
        }
        let before = String(text[text.startIndex..<range.lowerBound])
        let match  = String(text[range])
        let after  = String(text[range.upperBound...])
        return Text(before)
            + Text(match).bold().foregroundColor(MMColors.primary).underline()
            + Text(after)
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

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}

// MARK: - MacSearchFlowWrap (topic chips)

struct MacSearchFlowWrap: View {
    let items: [String]
    let query: String

    var body: some View {
        MacFlowLayout(spacing: 6) {
            ForEach(items, id: \.self) { item in
                let isHighlighted = !query.trimmingCharacters(in: .whitespaces).isEmpty &&
                    item.localizedCaseInsensitiveContains(query.trimmingCharacters(in: .whitespaces))
                Text(item)
                    .font(.system(size: 11, weight: isHighlighted ? .semibold : .regular))
                    .foregroundColor(isHighlighted ? MMColors.primary : MMColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(isHighlighted ? MMColors.primaryLight : MMColors.background)
                            .overlay(
                                Capsule()
                                    .stroke(isHighlighted ? MMColors.primary.opacity(0.3) : MMColors.border, lineWidth: 1)
                            )
                    )
            }
        }
    }
}

// MARK: - MacFlowLayout

struct MacFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }
        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}

// MARK: - Preview

#Preview {
    MacSearchView()
        .environmentObject(MeetingService.shared)
        .frame(width: 900, height: 600)
}
#endif
