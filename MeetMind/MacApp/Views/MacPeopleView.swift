#if os(macOS)
import SwiftUI

struct MacPeopleView: View {
    @EnvironmentObject var meetingService: MeetingService
    @State private var people: [PersonEntry] = []
    @State private var selectedPersonId: UUID?
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var hasExtracted = false

    var body: some View {
        HStack(spacing: 0) {
            // Left pane — People list
            peopleList
            Divider()
            // Right pane — Person detail
            personDetail
        }
        .background(MMColors.backgroundElevated)
        .onAppear {
            if !hasExtracted && people.isEmpty {
                extractPeople()
            }
        }
    }

    // MARK: - People List (left pane)

    private var peopleList: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Text("People")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(MMColors.textPrimary)

                if !people.isEmpty {
                    Text("\(filteredPeople.count)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(MMColors.textTertiary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(MMColors.background))
                }

                Spacer()

                Button {
                    extractPeople()
                } label: {
                    Image(systemName: isLoading ? "arrow.clockwise" : "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(MMColors.textTertiary)
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                        .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 12)

            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(MMColors.textTertiary)
                TextField("Search people...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(MMColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(MMColors.background))
            .padding(.horizontal, 14)
            .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 14)

            // List body
            if isLoading {
                loadingState
            } else if people.isEmpty && hasExtracted {
                emptyExtractedState
            } else if people.isEmpty {
                emptyInitialState
            } else if filteredPeople.isEmpty {
                noSearchResultsState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 3) {
                        ForEach(filteredPeople) { person in
                            personRow(person: person)
                                .padding(.horizontal, 10)
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
        }
        .frame(width: 260)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Person Row

    private func personRow(person: PersonEntry) -> some View {
        let isSelected = selectedPersonId == person.id
        return Button {
            selectedPersonId = person.id
        } label: {
            HStack(spacing: 10) {
                // Initials avatar
                ZStack {
                    Circle()
                        .fill(avatarColor(for: person.name))
                    Text(person.initials)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text(person.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(MMColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        if let company = person.company {
                            Text(company)
                                .font(.system(size: 11))
                                .foregroundColor(MMColors.primary)
                                .lineLimit(1)
                        }
                        if let role = person.role {
                            if person.company != nil {
                                Text("·")
                                    .font(.system(size: 11))
                                    .foregroundColor(MMColors.textTertiary)
                            }
                            Text(role)
                                .font(.system(size: 11))
                                .foregroundColor(MMColors.textTertiary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer(minLength: 4)

                Text("\(person.meetingCount)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isSelected ? MMColors.primary : MMColors.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(isSelected ? MMColors.primary.opacity(0.1) : MMColors.background)
                    )
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? MMColors.primary.opacity(0.08) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? MMColors.primary.opacity(0.18) : Color.clear)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Person Detail (right pane)

    @ViewBuilder
    private var personDetail: some View {
        if let personId = selectedPersonId,
           let person = people.first(where: { $0.id == personId }) {
            let personMeetings = meetingsFor(person: person)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Person header card
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(avatarColor(for: person.name))
                                .frame(width: 64, height: 64)
                            Text(person.initials)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(spacing: 6) {
                            Text(person.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(MMColors.textPrimary)

                            HStack(spacing: 12) {
                                if let company = person.company {
                                    HStack(spacing: 4) {
                                        Image(systemName: "building.2")
                                            .font(.system(size: 11))
                                            .foregroundColor(MMColors.primary)
                                        Text(company)
                                            .font(.system(size: 13))
                                            .foregroundColor(MMColors.primary)
                                    }
                                }
                                if let role = person.role {
                                    HStack(spacing: 4) {
                                        Image(systemName: "person.text.rectangle")
                                            .font(.system(size: 11))
                                            .foregroundColor(MMColors.textTertiary)
                                        Text(role)
                                            .font(.system(size: 13))
                                            .foregroundColor(MMColors.textSecondary)
                                    }
                                }
                            }
                        }

                        // Stats row
                        HStack(spacing: 0) {
                            Divider()
                                .frame(height: 1)

                            statPill(
                                value: "\(person.meetingCount)",
                                label: person.meetingCount == 1 ? "Meeting" : "Meetings",
                                icon: "waveform.circle",
                                color: MMColors.primary
                            )

                            Divider()
                                .frame(height: 32)
                                .padding(.horizontal, 8)

                            if let lastDate = person.lastMeetingDate {
                                statPill(
                                    value: lastDate.formatted(date: .abbreviated, time: .omitted),
                                    label: "Last Meeting",
                                    icon: "calendar",
                                    color: MMColors.info
                                )
                            }

                            Divider()
                                .frame(height: 1)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(MMColors.background)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(MMColors.border))
                        )
                        .padding(.horizontal, 4)
                    }
                    .padding(28)
                    .frame(maxWidth: .infinity)

                    Divider()

                    // Meetings section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "waveform")
                                .font(.system(size: 12))
                                .foregroundColor(MMColors.primary)
                            Text("Meetings with \(person.name.components(separatedBy: " ").first ?? person.name)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(MMColors.textPrimary)
                            Spacer()
                            Text("\(personMeetings.count)")
                                .font(.system(size: 12))
                                .foregroundColor(MMColors.textTertiary)
                        }

                        if personMeetings.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "waveform.slash")
                                        .font(.system(size: 24))
                                        .foregroundColor(MMColors.textTertiary.opacity(0.4))
                                    Text("No meetings found")
                                        .font(.system(size: 13))
                                        .foregroundColor(MMColors.textTertiary)
                                }
                                .padding(.vertical, 24)
                                Spacer()
                            }
                        } else {
                            VStack(spacing: 6) {
                                ForEach(personMeetings) { meeting in
                                    meetingRow(meeting: meeting)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 20)
                }
            }
        } else {
            noSelectionState
        }
    }

    // MARK: - Meeting Row

    private func meetingRow(meeting: Meeting) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(MMColors.primary.opacity(0.6))
                .frame(width: 3, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(meeting.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(MMColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(meeting.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11))
                        .foregroundColor(MMColors.textTertiary)

                    if let client = meeting.clientName {
                        Text("·")
                            .font(.system(size: 11))
                            .foregroundColor(MMColors.textTertiary)
                        Text(client)
                            .font(.system(size: 11))
                            .foregroundColor(MMColors.primary)
                            .lineLimit(1)
                    }

                    Text("·")
                        .font(.system(size: 11))
                        .foregroundColor(MMColors.textTertiary)

                    Text(formattedDuration(meeting.duration))
                        .font(.system(size: 11))
                        .foregroundColor(MMColors.textTertiary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(MMColors.background)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(MMColors.border))
        )
    }

    // MARK: - Stat Pill

    private func statPill(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(MMColors.textPrimary)
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(MMColors.textTertiary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty / Loading States

    private var loadingState: some View {
        VStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.9)
            Text("Analyzing transcripts...")
                .font(.system(size: 12))
                .foregroundColor(MMColors.textSecondary)
            Text("AI is detecting participants")
                .font(.system(size: 11))
                .foregroundColor(MMColors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyInitialState: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.3")
                .font(.system(size: 32))
                .foregroundColor(MMColors.textTertiary.opacity(0.4))
            Text("No people yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(MMColors.textSecondary)
            Text("Extract participants from\nyour meeting transcripts")
                .font(.system(size: 11))
                .foregroundColor(MMColors.textTertiary)
                .multilineTextAlignment(.center)
            Button {
                extractPeople()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 11))
                    Text("Extract People")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(MMColors.primary))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyExtractedState: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.slash")
                .font(.system(size: 28))
                .foregroundColor(MMColors.textTertiary.opacity(0.4))
            Text("No participants found")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(MMColors.textSecondary)
            Text("Complete more meetings with\ntranscripts to detect people")
                .font(.system(size: 11))
                .foregroundColor(MMColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noSearchResultsState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 22))
                .foregroundColor(MMColors.textTertiary.opacity(0.4))
            Text("No results for \"\(searchText)\"")
                .font(.system(size: 12))
                .foregroundColor(MMColors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noSelectionState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.circle")
                .font(.system(size: 40))
                .foregroundColor(MMColors.textTertiary.opacity(0.3))
            Text("Select a person")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(MMColors.textSecondary)
            Text("Choose someone from the list\nto see their meeting history")
                .font(.system(size: 12))
                .foregroundColor(MMColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data Extraction

    private func extractPeople() {
        let completedMeetings = meetingService.meetings.filter {
            $0.status == .complete && $0.rawTranscript != nil
        }
        guard !completedMeetings.isEmpty else {
            hasExtracted = true
            return
        }

        isLoading = true
        hasExtracted = true

        Task {
            var allEntries: [String: PersonEntry] = [:]

            // Seed with existing data so we don't lose previously cached entries
            for existing in people {
                let key = existing.name.lowercased().trimmingCharacters(in: .whitespaces)
                allEntries[key] = existing
            }

            for meeting in completedMeetings {
                guard let transcript = meeting.rawTranscript else { continue }
                do {
                    let participants = try await GroqService.shared.extractParticipants(transcript: transcript)
                    for p in participants {
                        let key = p.name.lowercased().trimmingCharacters(in: .whitespaces)
                        if var entry = allEntries[key] {
                            if !entry.meetingIds.contains(meeting.id) {
                                entry.meetingIds.insert(meeting.id)
                                entry.meetingCount = entry.meetingIds.count
                                if let ld = entry.lastMeetingDate {
                                    if meeting.date > ld { entry.lastMeetingDate = meeting.date }
                                } else {
                                    entry.lastMeetingDate = meeting.date
                                }
                            }
                            allEntries[key] = entry
                        } else {
                            allEntries[key] = PersonEntry(
                                name: p.name,
                                company: p.company,
                                role: p.role,
                                meetingCount: 1,
                                lastMeetingDate: meeting.date,
                                meetingIds: [meeting.id]
                            )
                        }
                    }
                } catch {
                    print("[MacPeopleView] Failed to extract from \(meeting.title): \(error)")
                }
            }

            await MainActor.run {
                people = Array(allEntries.values)
                    .sorted { ($0.lastMeetingDate ?? .distantPast) > ($1.lastMeetingDate ?? .distantPast) }
                isLoading = false
            }
        }
    }

    // MARK: - Helpers

    private var filteredPeople: [PersonEntry] {
        if searchText.isEmpty { return people }
        return people.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.company?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.role?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private func meetingsFor(person: PersonEntry) -> [Meeting] {
        meetingService.meetings
            .filter { person.meetingIds.contains($0.id) }
            .sorted { $0.date > $1.date }
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    private let avatarPalette: [Color] = [
        MMColors.primary,
        MMColors.info,
        MMColors.success,
        MMColors.warning,
        Color(hex: "8B5CF6"),
        Color(hex: "EC4899"),
        Color(hex: "14B8A6"),
        Color(hex: "F97316")
    ]

    private func avatarColor(for name: String) -> Color {
        let index = abs(name.hashValue) % avatarPalette.count
        return avatarPalette[index]
    }
}
#endif
