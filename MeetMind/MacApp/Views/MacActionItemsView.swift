#if os(macOS)
import SwiftUI

struct MacActionItemsView: View {
    @EnvironmentObject var meetingService: MeetingService

    // MARK: - Filter State

    enum OwnerFilter: String, CaseIterable {
        case all    = "All"
        case mine   = "Mine"
        case others = "Others"
    }

    enum StatusFilter: String, CaseIterable {
        case pending   = "Pending"
        case done      = "Done"
        case all       = "All"
    }

    @State private var ownerFilter: OwnerFilter  = .all
    @State private var statusFilter: StatusFilter = .pending
    @State private var searchText: String         = ""
    @State private var hoveredItemId: UUID?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()

            if allItems.isEmpty {
                emptyState(reason: .noMeetings)
            } else {
                VStack(spacing: 0) {
                    filterBar
                        .padding(.horizontal, 24)
                        .padding(.top, 14)
                        .padding(.bottom, 10)

                    Divider()

                    if overdueCount > 0 {
                        overdueBanner
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                            .padding(.bottom, 4)
                    }

                    statsRow
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    Divider()

                    if filteredItems.isEmpty {
                        emptyState(reason: .noMatches)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(filteredItems, id: \.item.id) { entry in
                                    actionItemRow(entry.item, meeting: entry.meeting)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                        }
                    }
                }
            }
        }
        .background(MMColors.backgroundElevated)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Action Items")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(MMColors.textPrimary)
                Text("\(pendingCount) pending · \(allItems.count) total")
                    .font(.system(size: 12))
                    .foregroundColor(MMColors.textTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 16) {
                // Owner segmented control
                VStack(alignment: .leading, spacing: 4) {
                    Text("Owner")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(MMColors.textTertiary)
                        .textCase(.uppercase)
                    Picker("", selection: $ownerFilter) {
                        ForEach(OwnerFilter.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }

                // Status segmented control
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(MMColors.textTertiary)
                        .textCase(.uppercase)
                    Picker("", selection: $statusFilter) {
                        ForEach(StatusFilter.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }

                Spacer()

                // Search bar
                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(MMColors.textTertiary)
                    TextField("Search action items…", text: $searchText)
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
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(MMColors.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(MMColors.border, lineWidth: 1)
                        )
                )
                .frame(width: 220)
            }
        }
    }

    // MARK: - Overdue Banner

    private var overdueBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MMColors.recording)

            Text(overdueCount == 1
                 ? "1 action item is overdue"
                 : "\(overdueCount) action items are overdue")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MMColors.recording)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(MMColors.recording.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(MMColors.recording.opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 10) {
            statPill(label: "Total",     count: allItems.count,    color: MMColors.primary)
            statPill(label: "Pending",   count: pendingCount,      color: MMColors.warning)
            statPill(label: "Completed", count: completedCount,    color: MMColors.success)
            statPill(label: "Overdue",   count: overdueCount,      color: MMColors.recording)
        }
    }

    private func statPill(label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Text("\(count)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(MMColors.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.18), lineWidth: 1)
                )
        )
    }

    // MARK: - Action Item Row

    private func actionItemRow(_ item: ActionItem, meeting: Meeting) -> some View {
        let isHovered  = hoveredItemId == item.id
        let itemIsOverdue = isOverdue(item.dueDate) && !item.isCompleted

        return HStack(alignment: .top, spacing: 12) {
            // Completion toggle
            Button {
                meetingService.toggleActionItemCompletion(
                    meetingId: meeting.id,
                    actionItemId: item.id
                )
            } label: {
                ZStack {
                    Circle()
                        .stroke(
                            item.isCompleted
                                ? MMColors.success
                                : itemIsOverdue
                                    ? MMColors.recording
                                    : MMColors.border,
                            lineWidth: 1.8
                        )
                        .frame(width: 22, height: 22)

                    if item.isCompleted {
                        Circle()
                            .fill(MMColors.success)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 1)

            // Content
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(item.text)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(
                            item.isCompleted
                                ? MMColors.textTertiary
                                : MMColors.textPrimary
                        )
                        .strikethrough(item.isCompleted, color: MMColors.textTertiary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if item.isMine {
                        Text("Mine")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(MMColors.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(MMColors.primary.opacity(0.1))
                            )
                    }
                }

                // Metadata row
                HStack(spacing: 10) {
                    if !item.owner.isEmpty {
                        Label(item.owner, systemImage: "person.fill")
                            .font(.system(size: 10))
                            .foregroundColor(
                                item.isMine ? MMColors.primary : MMColors.textTertiary
                            )
                    }

                    if let due = item.dueDate {
                        Label(formattedDate(due), systemImage: "calendar")
                            .font(.system(size: 10, weight: itemIsOverdue ? .semibold : .regular))
                            .foregroundColor(
                                itemIsOverdue
                                    ? MMColors.recording
                                    : isDueToday(due)
                                        ? MMColors.warning
                                        : MMColors.textTertiary
                            )
                        if itemIsOverdue {
                            Text("Overdue")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(MMColors.recording)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(MMColors.recording.opacity(0.1))
                                )
                        }
                    }

                    Label(meeting.title, systemImage: "waveform")
                        .font(.system(size: 10))
                        .foregroundColor(MMColors.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    isHovered
                        ? (itemIsOverdue
                            ? MMColors.recording.opacity(0.04)
                            : MMColors.background)
                        : Color.clear
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            itemIsOverdue && !item.isCompleted
                                ? MMColors.recording.opacity(isHovered ? 0.25 : 0.12)
                                : Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .onHover { h in hoveredItemId = h ? item.id : nil }
    }

    // MARK: - Empty State

    private enum EmptyReason { case noMeetings, noMatches }

    private func emptyState(reason: EmptyReason) -> some View {
        VStack(spacing: 12) {
            Image(systemName: reason == .noMeetings ? "checklist" : "magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(MMColors.textTertiary.opacity(0.4))
            Text(reason == .noMeetings ? "No action items yet" : "No items match your filters")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MMColors.textSecondary)
            Text(reason == .noMeetings
                 ? "Record a meeting to automatically extract action items."
                 : "Try adjusting the owner, status, or search filters.")
                .font(.system(size: 12))
                .foregroundColor(MMColors.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Computed Data

    private var allItems: [(item: ActionItem, meeting: Meeting)] {
        meetingService.allActionItems
    }

    private var filteredItems: [(item: ActionItem, meeting: Meeting)] {
        var result = allItems

        // Owner filter
        switch ownerFilter {
        case .all:    break
        case .mine:   result = result.filter { $0.item.isMine }
        case .others: result = result.filter { !$0.item.isMine }
        }

        // Status filter
        switch statusFilter {
        case .pending:   result = result.filter { !$0.item.isCompleted }
        case .done:      result = result.filter { $0.item.isCompleted }
        case .all:       break
        }

        // Text search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.item.text.lowercased().contains(query)
                    || $0.item.owner.lowercased().contains(query)
                    || $0.meeting.title.lowercased().contains(query)
            }
        }

        // Sort: overdue pending first → pending by due date → completed last
        return result.sorted { a, b in
            let aCompleted = a.item.isCompleted
            let bCompleted = b.item.isCompleted
            if aCompleted != bCompleted { return !aCompleted }

            let aOverdue = isOverdue(a.item.dueDate) && !aCompleted
            let bOverdue = isOverdue(b.item.dueDate) && !bCompleted
            if aOverdue != bOverdue { return aOverdue }

            switch (a.item.dueDate, b.item.dueDate) {
            case (.some(let dA), .some(let dB)): return dA < dB
            case (.some, .none):                 return true
            case (.none, .some):                 return false
            default:                             return a.meeting.date > b.meeting.date
            }
        }
    }

    private var pendingCount: Int {
        allItems.filter { !$0.item.isCompleted }.count
    }

    private var completedCount: Int {
        allItems.filter { $0.item.isCompleted }.count
    }

    private var overdueCount: Int {
        allItems.filter { !$0.item.isCompleted && isOverdue($0.item.dueDate) }.count
    }

    // MARK: - Helpers

    private func isOverdue(_ date: Date?) -> Bool {
        guard let date else { return false }
        return date < Calendar.current.startOfDay(for: Date())
    }

    private func isDueToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    MacActionItemsView()
        .environmentObject(MeetingService.shared)
        .frame(width: 720, height: 520)
}
#endif
