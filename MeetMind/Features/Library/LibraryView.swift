import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var meetingService: MeetingService
    @State private var searchText = ""
    @State private var selectedClient: ClientFolder?
    @State private var selectedMeeting: Meeting?
    @State private var showGlobalSearch = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    /// True when user has typed a full-text search query
    private var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MMColors.background.ignoresSafeArea()

                if clientFolders.isEmpty && !isSearchActive {
                    MMEmptyState(
                        icon: "folder",
                        title: "No client folders yet",
                        message: "Your client folders will appear here after your first meeting."
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Search bar - full text search
                            MMTextField(
                                placeholder: "Search meetings, briefs, transcripts...",
                                text: $searchText,
                                icon: "magnifyingglass"
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                            // Meeting Intelligence shortcut
                            NavigationLink {
                                MeetingInsightsView()
                                    .environmentObject(meetingService)
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(MMColors.info.opacity(0.12))
                                            .frame(width: 40, height: 40)

                                        Image(systemName: "chart.bar.xaxis")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(MMColors.info)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Meeting Intelligence")
                                            .font(MMTypography.headline)
                                            .foregroundColor(MMColors.textPrimary)

                                        Text("Analytics across all meetings")
                                            .font(MMTypography.caption1)
                                            .foregroundColor(MMColors.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(MMColors.textTertiary)
                                }
                                .padding(14)
                                .background(MMColors.cardBg)
                                .cornerRadius(14)
                                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)

                            // Action Items shortcut
                            NavigationLink {
                                ActionItemsView()
                                    .environmentObject(meetingService)
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(MMColors.primary.opacity(0.12))
                                            .frame(width: 40, height: 40)

                                        Image(systemName: "checklist")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(MMColors.primary)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Action Items")
                                            .font(MMTypography.headline)
                                            .foregroundColor(MMColors.textPrimary)

                                        let totalItems = meetingService.allActionItems.count
                                        let pendingItems = meetingService.allActionItems.filter { !$0.item.isCompleted }.count
                                        Text("\(pendingItems) pending of \(totalItems) total")
                                            .font(MMTypography.caption1)
                                            .foregroundColor(MMColors.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(MMColors.textTertiary)
                                }
                                .padding(14)
                                .background(MMColors.cardBg)
                                .cornerRadius(14)
                                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)

                            // Spaces shortcut
                            NavigationLink {
                                SpacesView()
                                    .environmentObject(meetingService)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "square.stack.3d.up.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(MMColors.primary)
                                    Text("Spaces")
                                        .font(MMTypography.footnoteMedium)
                                        .foregroundColor(MMColors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(MMColors.textTertiary)
                                }
                                .padding(12)
                                .background(MMColors.cardBg)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(MMColors.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)

                            if isSearchActive {
                                // Full-text search: flat list of matching meetings
                                searchResultsView
                            } else {
                                // Default: client folder grid
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(clientFolders) { folder in
                                        NavigationLink(value: folder) {
                                            clientFolderCard(folder)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 32)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showGlobalSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .accessibilityLabel("Global search")
                    .accessibilityHint("Open full search across all meetings")
                    NavigationLink {
                        PeopleView()
                            .environmentObject(meetingService)
                    } label: {
                        Image(systemName: "person.2")
                    }
                    NavigationLink {
                        RecipesView()
                            .environmentObject(meetingService)
                    } label: {
                        Image(systemName: "sparkles")
                    }
                }
            }
            .navigationDestination(for: ClientFolder.self) { folder in
                ClientMeetingsView(folder: folder, meetings: meetingsFor(folder))
            }
            .navigationDestination(item: $selectedMeeting) { meeting in
                MeetingDetailView(meeting: meeting)
            }
            .fullScreenCover(isPresented: $showGlobalSearch) {
                GlobalSearchView()
                    .environmentObject(meetingService)
            }
        }
    }

    // MARK: - Search Results

    private var searchResultsView: some View {
        let results = searchMeetings(query: searchText)

        return Group {
            if results.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(MMColors.textTertiary)

                    Text("No results for \"\(searchText)\"")
                        .font(MMTypography.headline)
                        .foregroundColor(MMColors.textSecondary)

                    Text("Try searching by meeting title, summary, transcript, or client name.")
                        .font(MMTypography.footnote)
                        .foregroundColor(MMColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                .padding(.horizontal, 40)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                        .font(MMTypography.caption1)
                        .foregroundColor(MMColors.textTertiary)
                        .padding(.horizontal, 20)

                    LazyVStack(spacing: 10) {
                        ForEach(results) { meeting in
                            Button {
                                selectedMeeting = meeting
                            } label: {
                                searchResultCard(meeting)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private func searchResultCard(_ meeting: Meeting) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(meeting.title)
                    .font(MMTypography.headline)
                    .foregroundColor(MMColors.textPrimary)
                    .lineLimit(1)

                Spacer()

                if let client = meeting.clientName {
                    MMBadge(text: client, variant: .client(clientColorHex(for: client)))
                }
            }

            HStack(spacing: 12) {
                Label(formattedDate(meeting.date), systemImage: "calendar")
                    .font(MMTypography.caption1)
                    .foregroundColor(MMColors.textSecondary)

                let minutes = Int(meeting.duration) / 60
                Label(minutes < 60 ? "\(minutes) min" : "\(minutes / 60)h \(minutes % 60)m", systemImage: "clock")
                    .font(MMTypography.caption1)
                    .foregroundColor(MMColors.textSecondary)
            }

            // Show snippet of matching content
            if let snippet = searchSnippet(for: meeting, query: searchText) {
                Text(snippet)
                    .font(MMTypography.footnote)
                    .foregroundColor(MMColors.textTertiary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MMColors.cardBg)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(meeting.title)\(meeting.clientName != nil ? ", client \(meeting.clientName!)" : "")")
        .accessibilityHint("Double-tap to view meeting details")
    }

    // MARK: - Full-Text Search

    private func searchMeetings(query: String) -> [Meeting] {
        let trimmed = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return [] }

        return meetingService.meetings
            .filter { meeting in
                // Search across title, summary, transcript, client name, and user notes
                meeting.title.localizedCaseInsensitiveContains(trimmed)
                || (meeting.briefSummary?.localizedCaseInsensitiveContains(trimmed) ?? false)
                || (meeting.rawTranscript?.localizedCaseInsensitiveContains(trimmed) ?? false)
                || (meeting.clientName?.localizedCaseInsensitiveContains(trimmed) ?? false)
                || (meeting.userNotes?.localizedCaseInsensitiveContains(trimmed) ?? false)
                || meeting.briefDecisions.contains(where: { $0.localizedCaseInsensitiveContains(trimmed) })
                || meeting.briefKeyTopics.contains(where: { $0.localizedCaseInsensitiveContains(trimmed) })
                || meeting.briefActionItems.contains(where: { $0.text.localizedCaseInsensitiveContains(trimmed) })
            }
            .sorted { $0.date > $1.date }
    }

    private func searchSnippet(for meeting: Meeting, query: String) -> String? {
        let trimmed = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return nil }

        // Priority: summary > transcript > decisions > notes
        let sources: [String?] = [
            meeting.briefSummary,
            meeting.rawTranscript,
            meeting.briefDecisions.first(where: { $0.localizedCaseInsensitiveContains(trimmed) }),
            meeting.userNotes
        ]

        for source in sources {
            guard let text = source,
                  let range = text.range(of: trimmed, options: .caseInsensitive) else {
                continue
            }
            // Extract a snippet around the match
            let startDistance = text.distance(from: text.startIndex, to: range.lowerBound)
            let snippetStart = text.index(range.lowerBound, offsetBy: -min(startDistance, 40), limitedBy: text.startIndex) ?? text.startIndex
            let snippetEnd = text.index(range.upperBound, offsetBy: 80, limitedBy: text.endIndex) ?? text.endIndex
            var snippet = String(text[snippetStart..<snippetEnd])
            if snippetStart != text.startIndex { snippet = "..." + snippet }
            if snippetEnd != text.endIndex { snippet += "..." }
            return snippet
        }

        return nil
    }

    // MARK: - Client Folder Card

    private func clientFolderCard(_ folder: ClientFolder) -> some View {
        let folderColor = Color(hex: folder.colorHex)

        return VStack(spacing: 14) {
            // Initial circle with accent ring
            ZStack {
                Circle()
                    .fill(folderColor.opacity(0.12))
                    .frame(width: 56, height: 56)

                Circle()
                    .strokeBorder(folderColor.opacity(0.25), lineWidth: 2)
                    .frame(width: 56, height: 56)

                Text(folder.initial)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(folderColor)
            }

            VStack(spacing: 4) {
                Text(folder.name)
                    .font(MMTypography.headline)
                    .foregroundColor(MMColors.textPrimary)
                    .lineLimit(1)

                Text("\(folder.meetingCount) meeting\(folder.meetingCount == 1 ? "" : "s")")
                    .font(MMTypography.caption1)
                    .foregroundColor(MMColors.textSecondary)

                if let lastDate = folder.lastMeetingDate {
                    Text(formattedDate(lastDate))
                        .font(MMTypography.caption2)
                        .foregroundColor(MMColors.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 12)
        .background(MMColors.cardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(folderColor.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 3)
        .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(folder.name) client folder")
        .accessibilityValue("\(folder.meetingCount) meeting\(folder.meetingCount == 1 ? "" : "s")\(folder.lastMeetingDate != nil ? ", last meeting \(formattedDate(folder.lastMeetingDate!))" : "")")
        .accessibilityHint("Double-tap to view meetings for this client")
    }

    // MARK: - Data

    private var clientFolders: [ClientFolder] {
        var folders: [ClientFolder] = []

        // Group meetings by client
        var grouped: [String: [Meeting]] = [:]
        for meeting in meetingService.meetings {
            let key = meeting.clientName ?? "General"
            grouped[key, default: []].append(meeting)
        }

        // General folder first
        if let generalMeetings = grouped["General"] {
            let sorted = generalMeetings.sorted { $0.date > $1.date }
            folders.append(ClientFolder(
                name: "General",
                colorHex: "9CA3AF",
                meetingCount: generalMeetings.count,
                lastMeetingDate: sorted.first?.date
            ))
        }

        // Other clients sorted alphabetically
        let clientNames = grouped.keys.filter { $0 != "General" }.sorted()
        for name in clientNames {
            guard let meetings = grouped[name] else { continue }
            let sorted = meetings.sorted { $0.date > $1.date }
            let colorHex = clientColorHex(for: name)
            folders.append(ClientFolder(
                name: name,
                colorHex: colorHex,
                meetingCount: meetings.count,
                lastMeetingDate: sorted.first?.date
            ))
        }

        return folders
    }

    private func meetingsFor(_ folder: ClientFolder) -> [Meeting] {
        let clientName = folder.name == "General" ? nil : folder.name
        return meetingService.meetings
            .filter { $0.clientName == clientName || (clientName == nil && $0.clientName == nil) }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Helpers

    private func clientColorHex(for name: String) -> String {
        let colors = ["6C5CE7", "FF4757", "00CE9E", "FFA502", "2D98FF", "E84393", "00B894", "FDCB6E"]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - ClientFolder Model

struct ClientFolder: Identifiable, Hashable {
    let id: String
    let name: String
    let colorHex: String
    let meetingCount: Int
    let lastMeetingDate: Date?

    var initial: String {
        String(name.prefix(1)).uppercased()
    }

    init(
        name: String,
        colorHex: String = "6C5CE7",
        meetingCount: Int = 0,
        lastMeetingDate: Date? = nil
    ) {
        self.id = name
        self.name = name
        self.colorHex = colorHex
        self.meetingCount = meetingCount
        self.lastMeetingDate = lastMeetingDate
    }
}

// MARK: - Preview

#Preview {
    LibraryView()
        .environmentObject(MeetingService.shared)
}
