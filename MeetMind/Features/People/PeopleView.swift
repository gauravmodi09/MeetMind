import SwiftUI

struct PeopleView: View {
    @EnvironmentObject var meetingService: MeetingService
    @StateObject private var viewModel = PeopleViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.people.isEmpty {
                    emptyView
                } else {
                    peopleList
                }
            }
            .background(MMColors.background)
            .navigationTitle("People")
            .searchable(text: $searchText, prompt: "Search people...")
            .onAppear {
                if viewModel.people.isEmpty {
                    viewModel.extractPeople(from: meetingService.meetings)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.people.isEmpty {
                        Button {
                            viewModel.extractPeople(from: meetingService.meetings)
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Detecting participants...")
                .font(.subheadline)
                .foregroundColor(MMColors.textSecondary)
            Text("Analyzing meeting transcripts with AI")
                .font(.caption)
                .foregroundColor(MMColors.textTertiary)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 48))
                .foregroundColor(MMColors.textTertiary)
            Text("No people detected yet")
                .font(.headline)
                .foregroundColor(MMColors.textPrimary)
            Text("Record meetings and the AI will automatically detect participants.")
                .font(.subheadline)
                .foregroundColor(MMColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var filteredPeople: [PersonEntry] {
        if searchText.isEmpty { return viewModel.people }
        return viewModel.people.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.company?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var peopleList: some View {
        List {
            ForEach(filteredPeople) { person in
                NavigationLink {
                    PersonDetailView(
                        person: person,
                        meetings: viewModel.meetings(for: person, allMeetings: meetingService.meetings)
                    )
                } label: {
                    PersonRow(person: person)
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Person Row

struct PersonRow: View {
    let person: PersonEntry

    var body: some View {
        HStack(spacing: 12) {
            Text(person.initials)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(MMColors.primary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(person.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(MMColors.textPrimary)

                HStack(spacing: 8) {
                    if let company = person.company {
                        Text(company)
                            .font(.caption)
                            .foregroundColor(MMColors.primary)
                    }
                    if let role = person.role {
                        Text(role)
                            .font(.caption)
                            .foregroundColor(MMColors.textTertiary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(person.meetingCount) mtg\(person.meetingCount == 1 ? "" : "s")")
                    .font(.caption.weight(.medium))
                    .foregroundColor(MMColors.textSecondary)
                if let lastDate = person.lastMeetingDate {
                    Text(lastDate, style: .date)
                        .font(.caption2)
                        .foregroundColor(MMColors.textTertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Person Detail View

struct PersonDetailView: View {
    let person: PersonEntry
    let meetings: [Meeting]

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Text(person.initials)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(MMColors.primary)
                        .clipShape(Circle())

                    Text(person.name)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(MMColors.textPrimary)

                    HStack(spacing: 16) {
                        if let company = person.company {
                            Label(company, systemImage: "building.2")
                                .font(.caption)
                                .foregroundColor(MMColors.textSecondary)
                        }
                        if let role = person.role {
                            Label(role, systemImage: "person.text.rectangle")
                                .font(.caption)
                                .foregroundColor(MMColors.textSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }

            Section("Meetings (\(meetings.count))") {
                if meetings.isEmpty {
                    Text("No meetings found")
                        .font(.subheadline)
                        .foregroundColor(MMColors.textTertiary)
                } else {
                    ForEach(meetings) { meeting in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(meeting.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(MMColors.textPrimary)
                            HStack {
                                Text(meeting.date, style: .date)
                                if let client = meeting.clientName {
                                    Text("| \(client)")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(MMColors.textSecondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Person Entry Model

struct PersonEntry: Identifiable {
    let id = UUID()
    let name: String
    let company: String?
    let role: String?
    var meetingCount: Int
    var lastMeetingDate: Date?
    var meetingIds: Set<UUID>

    var initials: String {
        let parts = name.components(separatedBy: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - ViewModel

@MainActor
class PeopleViewModel: ObservableObject {
    @Published var people: [PersonEntry] = []
    @Published var isLoading = false

    private let cacheKey = "cachedPeopleEntries"

    init() {
        loadCachedPeople()
    }

    func extractPeople(from meetings: [Meeting]) {
        let completedMeetings = meetings.filter { $0.status == .complete && $0.rawTranscript != nil }
        guard !completedMeetings.isEmpty else { return }

        isLoading = true

        Task {
            var allEntries: [String: PersonEntry] = [:]

            for meeting in completedMeetings {
                guard let transcript = meeting.rawTranscript else { continue }

                do {
                    let participants = try await GroqService.shared.extractParticipants(transcript: transcript)
                    for p in participants {
                        let key = p.name.lowercased().trimmingCharacters(in: .whitespaces)
                        if var existing = allEntries[key] {
                            existing.meetingCount += 1
                            existing.meetingIds.insert(meeting.id)
                            if let meetingDate = existing.lastMeetingDate, meeting.date > meetingDate {
                                existing.lastMeetingDate = meeting.date
                            } else if existing.lastMeetingDate == nil {
                                existing.lastMeetingDate = meeting.date
                            }
                            allEntries[key] = existing
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
                    print("[PeopleVM] Failed to extract from \(meeting.title): \(error)")
                }
            }

            people = Array(allEntries.values).sorted { ($0.lastMeetingDate ?? .distantPast) > ($1.lastMeetingDate ?? .distantPast) }
            cachePeople()
            isLoading = false
        }
    }

    func meetings(for person: PersonEntry, allMeetings: [Meeting]) -> [Meeting] {
        allMeetings.filter { person.meetingIds.contains($0.id) }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Cache

    private func cachePeople() {
        let cached = people.map { entry -> [String: Any] in
            var dict: [String: Any] = [
                "name": entry.name,
                "meetingCount": entry.meetingCount,
                "meetingIds": entry.meetingIds.map(\.uuidString)
            ]
            if let company = entry.company { dict["company"] = company }
            if let role = entry.role { dict["role"] = role }
            if let date = entry.lastMeetingDate { dict["lastMeetingDate"] = date.timeIntervalSince1970 }
            return dict
        }
        UserDefaults.standard.set(cached, forKey: cacheKey)
    }

    private func loadCachedPeople() {
        guard let cached = UserDefaults.standard.array(forKey: cacheKey) as? [[String: Any]] else { return }
        people = cached.compactMap { dict -> PersonEntry? in
            guard let name = dict["name"] as? String else { return nil }
            let ids = (dict["meetingIds"] as? [String])?.compactMap { UUID(uuidString: $0) } ?? []
            var lastDate: Date?
            if let ts = dict["lastMeetingDate"] as? TimeInterval {
                lastDate = Date(timeIntervalSince1970: ts)
            }
            return PersonEntry(
                name: name,
                company: dict["company"] as? String,
                role: dict["role"] as? String,
                meetingCount: dict["meetingCount"] as? Int ?? 0,
                lastMeetingDate: lastDate,
                meetingIds: Set(ids)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    PeopleView()
        .environmentObject(MeetingService.shared)
}
