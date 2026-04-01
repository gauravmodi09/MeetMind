#if os(macOS)
import SwiftUI

struct MacLibraryView: View {
    @EnvironmentObject var meetingService: MeetingService

    @State private var selectedClientName: String? = nil
    @State private var expandedClientName: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Library")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(MMColors.textPrimary)
                    Text("Insights across all your meetings")
                        .font(.system(size: 12))
                        .foregroundColor(MMColors.textTertiary)
                }
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // 1. Quick shortcut cards
                    quickShortcutCards

                    // 2. Stats row
                    statsRow

                    // 3. Client folders / expanded client view
                    if let selected = expandedClientName,
                       let group = clientGroups.first(where: { $0.name == selected }) {
                        expandedClientView(group)
                    } else if !clientGroups.isEmpty {
                        clientFoldersSection
                    }

                    // 4. Meeting type breakdown
                    sectionView("By Meeting Type", icon: "square.grid.2x2") {
                        VStack(spacing: 4) {
                            ForEach(templateCounts) { item in
                                templateRow(item: item)
                            }
                        }
                    }

                    // 5. Recent activity timeline
                    recentActivityTimeline

                    // 6. Weekly summary card
                    weeklySummaryCard
                }
                .padding(28)
            }
        }
        .background(MMColors.backgroundElevated)
    }

    // MARK: - Quick Shortcut Cards

    private var quickShortcutCards: some View {
        HStack(spacing: 12) {
            quickCard(
                icon: "checkmark.circle",
                label: "Action Items",
                value: "\(pendingActionItems)",
                subtitle: "pending",
                color: MMColors.success
            )
            quickCard(
                icon: "person.2",
                label: "People",
                value: "\(uniquePeopleCount)",
                subtitle: "unique people",
                color: MMColors.info
            )
            quickCard(
                icon: "chart.bar",
                label: "Insights",
                value: "\(meetingService.meetings.count)",
                subtitle: "total meetings",
                color: MMColors.primary
            )
        }
    }

    private func quickCard(icon: String, label: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(color.opacity(0.12))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(color)
                }
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MMColors.textSecondary)
                Spacer()
            }
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(MMColors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(MMColors.textTertiary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(MMColors.background)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(MMColors.border))
        )
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(
                value: "\(meetingService.meetings.count)",
                label: "Total Meetings",
                icon: "waveform.circle.fill",
                color: MMColors.primary,
                trend: meetingsThisWeek > 0 ? "+\(meetingsThisWeek) this week" : nil,
                trendUp: true
            )
            statCard(
                value: "\(totalActionItems)",
                label: "Action Items",
                icon: "checkmark.circle.fill",
                color: MMColors.success,
                trend: pendingActionItems > 0 ? "\(pendingActionItems) pending" : "All done",
                trendUp: pendingActionItems == 0
            )
            statCard(
                value: formattedTotalTime,
                label: "Time Recorded",
                icon: "clock.fill",
                color: MMColors.info,
                trend: nil,
                trendUp: nil
            )
            statCard(
                value: "\(uniqueClients)",
                label: "Clients",
                icon: "building.2.fill",
                color: MMColors.warning,
                trend: uniqueClients > 0 ? "\(clientGroups.count) active" : nil,
                trendUp: true
            )
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color, trend: String?, trendUp: Bool?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Spacer()
                if let trend, let up = trendUp {
                    HStack(spacing: 3) {
                        Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 8, weight: .bold))
                        Text(trend)
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(up ? MMColors.success : MMColors.warning)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(up ? MMColors.success.opacity(0.1) : MMColors.warning.opacity(0.1))
                    )
                }
            }
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(MMColors.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(MMColors.textTertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(MMColors.background)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(MMColors.border))
        )
    }

    // MARK: - Client Folders Section

    private var clientFoldersSection: some View {
        sectionView("Client Folders", icon: "folder.fill") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(clientGroups) { client in
                    clientFolderCard(client)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selectedClientName == client.name {
                                    expandedClientName = client.name
                                } else {
                                    selectedClientName = client.name
                                }
                            }
                        }
                }
            }
        }
    }

    private func clientFolderCard(_ client: ClientGroup) -> some View {
        let isSelected = selectedClientName == client.name
        let avatarColor = clientAvatarColor(for: client.name)
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(avatarColor.opacity(0.15))
                    .frame(width: 38, height: 38)
                Text(clientInitials(client.name))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(avatarColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(client.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MMColors.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text("\(client.meetingCount) meeting\(client.meetingCount == 1 ? "" : "s")")
                        .font(.system(size: 10))
                        .foregroundColor(MMColors.textTertiary)
                    Text("·")
                        .font(.system(size: 10))
                        .foregroundColor(MMColors.textTertiary)
                    Text(client.lastMeeting.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 10))
                        .foregroundColor(MMColors.textTertiary)
                }
            }
            Spacer()
            VStack(spacing: 2) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? avatarColor : MMColors.textTertiary)
                Image(systemName: isSelected ? "chevron.down" : "chevron.right")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isSelected ? avatarColor : MMColors.textTertiary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? avatarColor.opacity(0.05) : MMColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? avatarColor.opacity(0.4) : MMColors.border, lineWidth: isSelected ? 1.5 : 1)
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    // MARK: - Expanded Client View

    private func expandedClientView(_ client: ClientGroup) -> some View {
        let avatarColor = clientAvatarColor(for: client.name)
        let clientMeetings = meetingsForClient(client.name)
        return VStack(alignment: .leading, spacing: 16) {
            // Back button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedClientName = nil
                    selectedClientName = nil
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Back to all clients")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(MMColors.primary)
            }
            .buttonStyle(.plain)

            // Client header
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(avatarColor.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Text(clientInitials(client.name))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(avatarColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(client.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(MMColors.textPrimary)
                    HStack(spacing: 8) {
                        Label("\(client.meetingCount) meetings", systemImage: "waveform.circle")
                            .font(.system(size: 11))
                            .foregroundColor(MMColors.textSecondary)
                        Text("·")
                            .foregroundColor(MMColors.textTertiary)
                        Label("Last: \(client.lastMeeting.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                            .font(.system(size: 11))
                            .foregroundColor(MMColors.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(avatarColor.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(avatarColor.opacity(0.2)))
            )

            // Meetings list
            VStack(spacing: 6) {
                ForEach(clientMeetings) { meeting in
                    clientMeetingRow(meeting)
                }
            }
        }
    }

    private func clientMeetingRow(_ meeting: Meeting) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(meeting.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(MMColors.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(meeting.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 10))
                        .foregroundColor(MMColors.textTertiary)
                    if meeting.duration > 0 {
                        Text("·")
                            .font(.system(size: 10))
                            .foregroundColor(MMColors.textTertiary)
                        Text(formatDuration(meeting.duration))
                            .font(.system(size: 10))
                            .foregroundColor(MMColors.textTertiary)
                    }
                }
            }
            Spacer()
            // Template badge
            HStack(spacing: 4) {
                Image(systemName: meeting.template.icon)
                    .font(.system(size: 9))
                Text(meeting.template.rawValue)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundColor(MMColors.primary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(MMColors.primary.opacity(0.08))
                    .overlay(Capsule().stroke(MMColors.primary.opacity(0.2)))
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(MMColors.background)
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(MMColors.border))
        )
    }

    // MARK: - Section Builder

    private func sectionView<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(MMColors.primary)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MMColors.textPrimary)
            }
            content()
        }
    }

    // MARK: - Template Row (with progress bar + icon)

    private func templateRow(item: TemplateCount) -> some View {
        let maxCount = templateCounts.first?.count ?? 1
        let fraction = CGFloat(item.count) / CGFloat(max(maxCount, 1))
        return HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(MMColors.primary.opacity(0.1))
                    .frame(width: 26, height: 26)
                Image(systemName: item.template.icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(MMColors.primary)
            }
            Text(item.template.rawValue)
                .font(.system(size: 13))
                .foregroundColor(MMColors.textPrimary)
            Spacer()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(MMColors.border)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(MMColors.primary.opacity(0.6))
                        .frame(width: geo.size.width * fraction, height: 6)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(width: 80, height: 20)
            Text("\(item.count)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(MMColors.primary)
                .frame(width: 24, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(MMColors.background)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(MMColors.border))
        )
    }

    // MARK: - Recent Activity Timeline

    private var recentActivityTimeline: some View {
        sectionView("Recent Activity", icon: "clock.arrow.circlepath") {
            let recent = meetingService.meetings.sorted { $0.date > $1.date }.prefix(10)
            VStack(spacing: 0) {
                ForEach(Array(recent.enumerated()), id: \.element.id) { index, meeting in
                    HStack(alignment: .top, spacing: 14) {
                        // Timeline indicator
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(MMColors.primary.opacity(0.15))
                                    .frame(width: 10, height: 10)
                                Circle()
                                    .fill(MMColors.primary)
                                    .frame(width: 5, height: 5)
                            }
                            if index < Int(recent.count) - 1 {
                                Rectangle()
                                    .fill(MMColors.border)
                                    .frame(width: 1.5)
                                    .frame(minHeight: 32)
                            }
                        }
                        .frame(width: 14)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(meeting.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(MMColors.textPrimary)
                                .lineLimit(1)
                            HStack(spacing: 6) {
                                Text(meeting.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 10))
                                    .foregroundColor(MMColors.textTertiary)
                                if let client = meeting.clientName {
                                    Text("·")
                                        .font(.system(size: 10))
                                        .foregroundColor(MMColors.textTertiary)
                                    Text(client)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(MMColors.primary)
                                }
                            }
                        }
                        .padding(.top, -1)
                        .padding(.bottom, index < Int(recent.count) - 1 ? 12 : 0)

                        Spacer()
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(MMColors.background)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(MMColors.border))
            )
        }
    }

    // MARK: - Weekly Summary Card

    private var weeklySummaryCard: some View {
        sectionView("Weekly Summary", icon: "calendar.badge.checkmark") {
            HStack(spacing: 12) {
                // This week vs last week
                weekStatBlock(
                    icon: "waveform.circle.fill",
                    label: "This Week",
                    value: "\(meetingsThisWeek)",
                    comparison: "vs \(meetingsLastWeek) last week",
                    color: MMColors.primary,
                    up: meetingsThisWeek >= meetingsLastWeek
                )
                Divider()
                    .frame(height: 48)
                // Action items created vs completed
                weekStatBlock(
                    icon: "checkmark.circle.fill",
                    label: "Action Items",
                    value: "\(actionItemsCompletedThisWeek)/\(actionItemsThisWeek)",
                    comparison: "created vs completed",
                    color: MMColors.success,
                    up: actionItemsCompletedThisWeek >= actionItemsThisWeek / max(1, actionItemsThisWeek) * actionItemsThisWeek
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(MMColors.background)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(MMColors.border))
            )
        }
    }

    private func weekStatBlock(icon: String, label: String, value: String, comparison: String, color: Color, up: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(MMColors.textSecondary)
            }
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(MMColors.textPrimary)
            HStack(spacing: 3) {
                Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 8, weight: .bold))
                Text(comparison)
                    .font(.system(size: 10))
            }
            .foregroundColor(up ? MMColors.success : MMColors.warning)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Computed Properties

    private var totalActionItems: Int {
        meetingService.meetings.reduce(0) { $0 + $1.briefActionItems.count }
    }

    private var pendingActionItems: Int {
        meetingService.meetings.reduce(0) { $0 + $1.briefActionItems.filter { !$0.isCompleted }.count }
    }

    private var uniqueClients: Int {
        Set(meetingService.meetings.compactMap { $0.clientName }).count
    }

    private var uniquePeopleCount: Int {
        // Count unique non-empty owners from action items as a proxy for people
        let owners = meetingService.meetings.flatMap { $0.briefActionItems.map { $0.owner } }.filter { !$0.isEmpty }
        return max(Set(owners).count, uniqueClients)
    }

    private var formattedTotalTime: String {
        let totalMinutes = Int(meetingService.meetings.reduce(0) { $0 + $1.duration }) / 60
        if totalMinutes < 60 { return "\(totalMinutes)m" }
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }

    private var meetingsThisWeek: Int {
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return meetingService.meetings.filter { $0.date >= startOfWeek }.count
    }

    private var meetingsLastWeek: Int {
        let cal = Calendar.current
        let startOfThisWeek = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let startOfLastWeek = cal.date(byAdding: .weekOfYear, value: -1, to: startOfThisWeek) ?? Date()
        return meetingService.meetings.filter { $0.date >= startOfLastWeek && $0.date < startOfThisWeek }.count
    }

    private var actionItemsThisWeek: Int {
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return meetingService.meetings.filter { $0.date >= startOfWeek }
            .reduce(0) { $0 + $1.briefActionItems.count }
    }

    private var actionItemsCompletedThisWeek: Int {
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return meetingService.meetings.filter { $0.date >= startOfWeek }
            .reduce(0) { $0 + $1.briefActionItems.filter { $0.isCompleted }.count }
    }

    // MARK: - Client Groups

    private struct ClientGroup: Identifiable {
        let name: String
        let meetingCount: Int
        let lastMeeting: Date
        var id: String { name }
    }

    private var clientGroups: [ClientGroup] {
        let grouped = Dictionary(grouping: meetingService.meetings.filter { $0.clientName != nil }) { $0.clientName! }
        return grouped.map { name, meetings in
            ClientGroup(
                name: name,
                meetingCount: meetings.count,
                lastMeeting: meetings.max(by: { $0.date < $1.date })?.date ?? Date()
            )
        }
        .sorted { $0.meetingCount > $1.meetingCount }
    }

    private func meetingsForClient(_ name: String) -> [Meeting] {
        meetingService.meetings
            .filter { $0.clientName == name }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Template Counts

    private struct TemplateCount: Identifiable {
        let template: MeetingTemplate
        let count: Int
        var id: String { template.rawValue }
    }

    private var templateCounts: [TemplateCount] {
        let grouped = Dictionary(grouping: meetingService.meetings, by: \.template)
        return grouped.map { TemplateCount(template: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    // MARK: - Helpers

    private func clientInitials(_ name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private let avatarPalette: [Color] = [
        MMColors.primary, MMColors.success, MMColors.info,
        MMColors.warning, Color(hex: "EC4899"), Color(hex: "14B8A6")
    ]

    private func clientAvatarColor(for name: String) -> Color {
        let index = abs(name.hashValue) % avatarPalette.count
        return avatarPalette[index]
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        if mins < 60 { return "\(mins)m" }
        let h = mins / 60
        let m = mins % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}
#endif
