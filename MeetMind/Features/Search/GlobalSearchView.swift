import SwiftUI

// MARK: - Search Result Types

enum SearchResultType: String {
    case meeting = "Meetings"
    case actionItem = "Action Items"
    case person = "People"
}

struct SearchResult: Identifiable {
    let id = UUID()
    let type: SearchResultType
    let title: String
    let snippet: String
    let highlightRange: Range<String.Index>?
    let meetingTitle: String
    let meetingDate: Date
    let meetingId: UUID
}

// MARK: - Global Search View

struct GlobalSearchView: View {
    @EnvironmentObject var meetingService: MeetingService
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var results: [SearchResultType: [SearchResult]] = [:]
    @State private var selectedMeeting: Meeting?
    @FocusState private var isSearchFocused: Bool

    @AppStorage("recentSearches") private var recentSearchesData: Data = Data()

    private var recentSearches: [String] {
        (try? JSONDecoder().decode([String].self, from: recentSearchesData)) ?? []
    }

    private let suggestionChips = [
        "What did we decide about...",
        "Action items from...",
        "Meetings with..."
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                MMColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar

                    if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                        emptyStateView
                    } else if results.isEmpty {
                        noResultsView
                    } else {
                        searchResultsList
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(MMColors.primary)
                }
            }
            .navigationDestination(item: $selectedMeeting) { meeting in
                MeetingDetailView(meeting: meeting)
            }
            .onAppear {
                isSearchFocused = true
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(MMColors.textTertiary)
                .font(.system(size: 16, weight: .medium))

            TextField("Search meetings, action items, people...", text: $searchText)
                .font(MMTypography.body)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    saveRecentSearch(searchText)
                }
                .onChange(of: searchText) { _, newValue in
                    performSearch(query: newValue)
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    results = [:]
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(MMColors.textTertiary)
                        .font(.system(size: 16))
                }
                .accessibilityLabel("Clear search")
            }

            // Voice search
            DictationButton(text: $searchText)
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(MMColors.cardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSearchFocused ? MMColors.primary : MMColors.border, lineWidth: isSearchFocused ? 2 : 1)
        )
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Empty State (suggestions + recents)

    private var emptyStateView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Recent searches
                if !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Recent Searches")
                                .font(MMTypography.headline)
                                .foregroundColor(MMColors.textPrimary)

                            Spacer()

                            Button("Clear") {
                                clearRecentSearches()
                            }
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.textTertiary)
                        }

                        ForEach(recentSearches, id: \.self) { query in
                            Button {
                                searchText = query
                                performSearch(query: query)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 14))
                                        .foregroundColor(MMColors.textTertiary)

                                    Text(query)
                                        .font(MMTypography.body)
                                        .foregroundColor(MMColors.textPrimary)
                                        .lineLimit(1)

                                    Spacer()
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Suggestion chips
                VStack(alignment: .leading, spacing: 10) {
                    Text("Try searching")
                        .font(MMTypography.headline)
                        .foregroundColor(MMColors.textPrimary)

                    FlowLayout(spacing: 8) {
                        ForEach(suggestionChips, id: \.self) { chip in
                            Button {
                                searchText = chip
                                performSearch(query: chip)
                            } label: {
                                Text(chip)
                                    .font(MMTypography.footnote)
                                    .foregroundColor(MMColors.primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(MMColors.primaryLight)
                                    .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    // MARK: - No Results

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(MMColors.textTertiary)

            Text("No results for \"\(searchText)\"")
                .font(MMTypography.headline)
                .foregroundColor(MMColors.textSecondary)

            Text("Try a different search term or check your spelling.")
                .font(MMTypography.footnote)
                .foregroundColor(MMColors.textTertiary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Search Results List

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                let orderedTypes: [SearchResultType] = [.meeting, .actionItem, .person]

                ForEach(orderedTypes, id: \.rawValue) { type in
                    if let typeResults = results[type], !typeResults.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: iconForType(type))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(MMColors.primary)

                                Text(type.rawValue)
                                    .font(MMTypography.headline)
                                    .foregroundColor(MMColors.textPrimary)

                                Text("(\(typeResults.count))")
                                    .font(MMTypography.caption1)
                                    .foregroundColor(MMColors.textTertiary)
                            }

                            ForEach(typeResults) { result in
                                Button {
                                    saveRecentSearch(searchText)
                                    if let meeting = meetingService.meetings.first(where: { $0.id == result.meetingId }) {
                                        selectedMeeting = meeting
                                    }
                                } label: {
                                    searchResultCard(result)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    private func searchResultCard(_ result: SearchResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(result.title)
                .font(MMTypography.footnoteMedium)
                .foregroundColor(MMColors.textPrimary)
                .lineLimit(2)

            // Snippet with keyword highlighted
            highlightedSnippet(result.snippet, query: searchText)
                .font(MMTypography.footnote)
                .lineLimit(2)

            HStack(spacing: 8) {
                if result.type != .meeting {
                    Text(result.meetingTitle)
                        .font(MMTypography.caption2)
                        .foregroundColor(MMColors.primary)
                        .lineLimit(1)
                }

                Text(formattedDate(result.meetingDate))
                    .font(MMTypography.caption2)
                    .foregroundColor(MMColors.textTertiary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MMColors.cardBg)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(result.type.rawValue) result: \(result.title)")
        .accessibilityHint("Double-tap to view the source meeting")
    }

    // MARK: - Search Logic

    private func performSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else {
            results = [:]
            return
        }

        var meetingResults: [SearchResult] = []
        var actionResults: [SearchResult] = []
        var personResults: [SearchResult] = []

        for meeting in meetingService.meetings {
            // Search meeting titles and summaries
            if meeting.title.localizedCaseInsensitiveContains(trimmed) {
                let snippet = meeting.briefSummary ?? "Meeting on \(formattedDate(meeting.date))"
                meetingResults.append(SearchResult(
                    type: .meeting,
                    title: meeting.title,
                    snippet: String(snippet.prefix(120)),
                    highlightRange: nil,
                    meetingTitle: meeting.title,
                    meetingDate: meeting.date,
                    meetingId: meeting.id
                ))
            } else if let summary = meeting.briefSummary, summary.localizedCaseInsensitiveContains(trimmed) {
                let snippet = extractSnippet(from: summary, around: trimmed)
                meetingResults.append(SearchResult(
                    type: .meeting,
                    title: meeting.title,
                    snippet: snippet,
                    highlightRange: nil,
                    meetingTitle: meeting.title,
                    meetingDate: meeting.date,
                    meetingId: meeting.id
                ))
            } else if let transcript = meeting.rawTranscript, transcript.localizedCaseInsensitiveContains(trimmed) {
                let snippet = extractSnippet(from: transcript, around: trimmed)
                meetingResults.append(SearchResult(
                    type: .meeting,
                    title: meeting.title,
                    snippet: snippet,
                    highlightRange: nil,
                    meetingTitle: meeting.title,
                    meetingDate: meeting.date,
                    meetingId: meeting.id
                ))
            } else if let client = meeting.clientName, client.localizedCaseInsensitiveContains(trimmed) {
                meetingResults.append(SearchResult(
                    type: .meeting,
                    title: meeting.title,
                    snippet: "Client: \(client)",
                    highlightRange: nil,
                    meetingTitle: meeting.title,
                    meetingDate: meeting.date,
                    meetingId: meeting.id
                ))
            }

            // Search action items
            for item in meeting.briefActionItems {
                if item.text.localizedCaseInsensitiveContains(trimmed) {
                    actionResults.append(SearchResult(
                        type: .actionItem,
                        title: item.text,
                        snippet: "\(item.owner.isEmpty ? "" : "Owner: \(item.owner)")\(item.isMine ? " [Mine]" : "")",
                        highlightRange: nil,
                        meetingTitle: meeting.title,
                        meetingDate: meeting.date,
                        meetingId: meeting.id
                    ))
                }
            }

            // Search people / owners
            for item in meeting.briefActionItems {
                if !item.owner.isEmpty && item.owner.localizedCaseInsensitiveContains(trimmed) {
                    // Avoid duplicate person entries for same meeting
                    let alreadyAdded = personResults.contains { $0.meetingId == meeting.id && $0.title == item.owner }
                    if !alreadyAdded {
                        personResults.append(SearchResult(
                            type: .person,
                            title: item.owner,
                            snippet: "Mentioned in \(meeting.title)",
                            highlightRange: nil,
                            meetingTitle: meeting.title,
                            meetingDate: meeting.date,
                            meetingId: meeting.id
                        ))
                    }
                }
            }

            // Search client names as people
            if let client = meeting.clientName, client.localizedCaseInsensitiveContains(trimmed) {
                let alreadyAdded = personResults.contains { $0.meetingId == meeting.id && $0.title == client }
                if !alreadyAdded {
                    personResults.append(SearchResult(
                        type: .person,
                        title: client,
                        snippet: "Client for \(meeting.title)",
                        highlightRange: nil,
                        meetingTitle: meeting.title,
                        meetingDate: meeting.date,
                        meetingId: meeting.id
                    ))
                }
            }
        }

        var grouped: [SearchResultType: [SearchResult]] = [:]
        if !meetingResults.isEmpty { grouped[.meeting] = meetingResults }
        if !actionResults.isEmpty { grouped[.actionItem] = actionResults }
        if !personResults.isEmpty { grouped[.person] = personResults }
        results = grouped
    }

    // MARK: - Helpers

    private func extractSnippet(from text: String, around query: String) -> String {
        guard let range = text.range(of: query, options: .caseInsensitive) else {
            return String(text.prefix(120))
        }
        let startDistance = text.distance(from: text.startIndex, to: range.lowerBound)
        let snippetStart = text.index(range.lowerBound, offsetBy: -min(startDistance, 40), limitedBy: text.startIndex) ?? text.startIndex
        let snippetEnd = text.index(range.upperBound, offsetBy: 80, limitedBy: text.endIndex) ?? text.endIndex
        var snippet = String(text[snippetStart..<snippetEnd])
        if snippetStart != text.startIndex { snippet = "..." + snippet }
        if snippetEnd != text.endIndex { snippet += "..." }
        return snippet
    }

    private func highlightedSnippet(_ text: String, query: String) -> Text {
        let lowered = text.lowercased()
        let queryLower = query.trimmingCharacters(in: .whitespaces).lowercased()

        guard !queryLower.isEmpty, let range = lowered.range(of: queryLower) else {
            return Text(text).foregroundColor(MMColors.textTertiary)
        }

        let before = String(text[text.startIndex..<range.lowerBound])
        let match = String(text[range])
        let after = String(text[range.upperBound...])

        return Text(before).foregroundColor(MMColors.textTertiary)
            + Text(match).bold().foregroundColor(MMColors.textPrimary)
            + Text(after).foregroundColor(MMColors.textTertiary)
    }

    private func iconForType(_ type: SearchResultType) -> String {
        switch type {
        case .meeting:    return "doc.text"
        case .actionItem: return "checklist"
        case .person:     return "person"
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Recent Searches

    private func saveRecentSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        var searches = recentSearches
        searches.removeAll { $0 == trimmed }
        searches.insert(trimmed, at: 0)
        if searches.count > 5 {
            searches = Array(searches.prefix(5))
        }
        recentSearchesData = (try? JSONEncoder().encode(searches)) ?? Data()
    }

    private func clearRecentSearches() {
        recentSearchesData = (try? JSONEncoder().encode([String]())) ?? Data()
    }
}

// MARK: - Flow Layout (for suggestion chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

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
            maxX = max(maxX, x)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}

// MARK: - Preview

#Preview {
    GlobalSearchView()
        .environmentObject(MeetingService.shared)
}
