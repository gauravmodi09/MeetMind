import SwiftUI

struct CompanyView: View {
    @EnvironmentObject var meetingService: MeetingService
    let people: [PersonEntry]
    @State private var searchText = ""

    var companies: [CompanyEntry] {
        var result: [String: CompanyEntry] = [:]

        for person in people {
            let companyName = person.company ?? "Unknown"
            let key = companyName.lowercased()

            if var existing = result[key] {
                existing.participants.insert(person.name)
                existing.meetingIds.formUnion(person.meetingIds)
                if let date = person.lastMeetingDate {
                    if let existingDate = existing.lastMeetingDate, date > existingDate {
                        existing.lastMeetingDate = date
                    } else if existing.lastMeetingDate == nil {
                        existing.lastMeetingDate = date
                    }
                }
                result[key] = existing
            } else {
                result[key] = CompanyEntry(
                    name: companyName,
                    participants: [person.name],
                    meetingIds: person.meetingIds,
                    lastMeetingDate: person.lastMeetingDate
                )
            }
        }

        let entries = Array(result.values).sorted {
            $0.meetingIds.count > $1.meetingIds.count
        }

        if searchText.isEmpty { return entries }
        return entries.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if companies.isEmpty {
                    emptyView
                } else {
                    companyList
                }
            }
            .background(MMColors.background)
            .navigationTitle("Companies")
            .searchable(text: $searchText, prompt: "Search companies...")
        }
    }

    // MARK: - Subviews

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2")
                .font(.system(size: 48))
                .foregroundColor(MMColors.textTertiary)
            Text("No companies detected")
                .font(.headline)
                .foregroundColor(MMColors.textPrimary)
            Text("Companies are auto-detected from meeting participants. Record more meetings to populate this view.")
                .font(.subheadline)
                .foregroundColor(MMColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var companyList: some View {
        List {
            ForEach(companies) { company in
                NavigationLink {
                    CompanyDetailView(
                        company: company,
                        meetings: meetingsForCompany(company),
                        people: peopleForCompany(company)
                    )
                } label: {
                    CompanyRow(company: company)
                }
            }
        }
        .listStyle(.plain)
    }

    private func meetingsForCompany(_ company: CompanyEntry) -> [Meeting] {
        meetingService.meetings.filter { company.meetingIds.contains($0.id) }
            .sorted { $0.date > $1.date }
    }

    private func peopleForCompany(_ company: CompanyEntry) -> [PersonEntry] {
        people.filter { person in
            company.participants.contains(person.name)
        }
    }
}

// MARK: - Company Row

struct CompanyRow: View {
    let company: CompanyEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "building.2.fill")
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(MMColors.info)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(company.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(MMColors.textPrimary)

                HStack(spacing: 12) {
                    Label("\(company.participants.count) people", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(MMColors.textSecondary)
                    Label("\(company.meetingIds.count) meetings", systemImage: "mic")
                        .font(.caption)
                        .foregroundColor(MMColors.textSecondary)
                }
            }

            Spacer()

            if let date = company.lastMeetingDate {
                Text(date, style: .date)
                    .font(.caption2)
                    .foregroundColor(MMColors.textTertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Company Detail View

struct CompanyDetailView: View {
    let company: CompanyEntry
    let meetings: [Meeting]
    let people: [PersonEntry]

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(MMColors.info)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    Text(company.name)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(MMColors.textPrimary)

                    HStack(spacing: 20) {
                        statBadge(value: "\(people.count)", label: "People")
                        statBadge(value: "\(meetings.count)", label: "Meetings")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }

            Section("People") {
                ForEach(people) { person in
                    HStack(spacing: 10) {
                        Text(person.initials)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(MMColors.primary)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(person.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(MMColors.textPrimary)
                            if let role = person.role {
                                Text(role)
                                    .font(.caption)
                                    .foregroundColor(MMColors.textTertiary)
                            }
                        }

                        Spacer()

                        Text("\(person.meetingCount) mtg\(person.meetingCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(MMColors.textSecondary)
                    }
                }
            }

            Section("Meetings") {
                ForEach(meetings) { meeting in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meeting.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(MMColors.textPrimary)
                        Text(meeting.date, style: .date)
                            .font(.caption)
                            .foregroundColor(MMColors.textSecondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(company.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statBadge(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundColor(MMColors.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundColor(MMColors.textSecondary)
        }
    }
}

// MARK: - Company Entry Model

struct CompanyEntry: Identifiable {
    let id = UUID()
    var name: String
    var participants: Set<String>
    var meetingIds: Set<UUID>
    var lastMeetingDate: Date?
}

// MARK: - Preview

#Preview {
    CompanyView(people: [])
        .environmentObject(MeetingService.shared)
}
