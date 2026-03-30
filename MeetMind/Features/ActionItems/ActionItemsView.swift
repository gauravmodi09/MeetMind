import SwiftUI

struct ActionItemsView: View {
    @EnvironmentObject var meetingService: MeetingService

    @State private var filterMode: FilterMode = .all
    @State private var ownerFilter: String? = nil
    @State private var showCompletedFilter: CompletedFilter = .pending
    @State private var selectedMeeting: Meeting?

    enum FilterMode: String, CaseIterable {
        case all = "All"
        case mine = "Mine"
        case others = "Others"
    }

    enum CompletedFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case completed = "Done"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MMColors.background.ignoresSafeArea()

                if allItems.isEmpty {
                    MMEmptyState(
                        icon: "checklist",
                        title: "No action items yet",
                        message: "Action items from your meetings will appear here. Record a meeting to get started."
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Overdue warning banner
                            if overdueCount > 0 {
                                overdueBanner
                                    .padding(.horizontal, 20)
                            }

                            // Filter pills
                            filterBar
                                .padding(.horizontal, 20)

                            // Stats row
                            statsRow
                                .padding(.horizontal, 20)

                            // Items list
                            LazyVStack(spacing: 8) {
                                ForEach(filteredItems, id: \.item.id) { entry in
                                    actionItemRow(entry.item, meeting: entry.meeting)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Action Items")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .navigationDestination(item: $selectedMeeting) { meeting in
                MeetingDetailView(meeting: meeting)
            }
        }
    }

    // MARK: - Overdue Banner

    private var overdueBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(MMColors.recording)

            Text("You have \(overdueCount) overdue item\(overdueCount == 1 ? "" : "s")")
                .font(MMTypography.footnoteMedium)
                .foregroundColor(MMColors.recording)

            Spacer()
        }
        .padding(14)
        .background(MMColors.recordingLight)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(MMColors.recording.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Owner filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FilterMode.allCases, id: \.self) { mode in
                        filterPill(mode.rawValue, isSelected: filterMode == mode) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                filterMode = mode
                            }
                        }
                    }

                    Divider()
                        .frame(height: 20)

                    ForEach(CompletedFilter.allCases, id: \.self) { filter in
                        filterPill(filter.rawValue, isSelected: showCompletedFilter == filter) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showCompletedFilter = filter
                            }
                        }
                    }
                }
            }

            // Person filter
            if !uniqueOwners.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        filterPill("All People", isSelected: ownerFilter == nil) {
                            withAnimation { ownerFilter = nil }
                        }
                        ForEach(uniqueOwners, id: \.self) { owner in
                            filterPill(owner, isSelected: ownerFilter == owner) {
                                withAnimation { ownerFilter = owner }
                            }
                        }
                    }
                }
            }
        }
    }

    private func filterPill(_ text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(MMTypography.caption1)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : MMColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? MMColors.primary : MMColors.cardBg)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? MMColors.primary : MMColors.border, lineWidth: 1)
                )
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 16) {
            statBadge(count: allItems.count, label: "Total", color: MMColors.info)
            statBadge(count: pendingCount, label: "Pending", color: MMColors.warning)
            statBadge(count: completedCount, label: "Done", color: MMColors.success)
            statBadge(count: overdueCount, label: "Overdue", color: MMColors.recording)
        }
    }

    private func statBadge(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(MMTypography.caption2)
                .foregroundColor(MMColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }

    // MARK: - Action Item Row

    private func actionItemRow(_ item: ActionItem, meeting: Meeting) -> some View {
        MMCard(padding: 14) {
            HStack(alignment: .top, spacing: 12) {
                // Checkbox
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        meetingService.toggleActionItemCompletion(
                            meetingId: meeting.id,
                            actionItemId: item.id
                        )
                    }
                } label: {
                    Circle()
                        .fill(
                            item.isCompleted ? MMColors.success :
                            item.isMine ? MMColors.warning.opacity(0.2) :
                            MMColors.border
                        )
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(
                                    item.isCompleted ? MMColors.success :
                                    item.isMine ? MMColors.warning :
                                    MMColors.textTertiary,
                                    lineWidth: 2
                                )
                        )
                        .overlay(
                            item.isCompleted ?
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                            : nil
                        )
                }
                .accessibilityLabel(item.isCompleted ? "Mark incomplete" : "Mark complete")

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.text)
                        .font(MMTypography.body)
                        .foregroundColor(item.isCompleted ? MMColors.textTertiary : MMColors.textPrimary)
                        .strikethrough(item.isCompleted)

                    HStack(spacing: 8) {
                        if !item.owner.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 10))
                                Text(item.owner)
                            }
                            .font(MMTypography.caption1)
                            .foregroundColor(item.isMine ? MMColors.warning : MMColors.textSecondary)
                        }

                        if let due = item.dueDate {
                            HStack(spacing: 3) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))
                                Text(formattedShortDate(due))
                            }
                            .font(MMTypography.caption1)
                            .foregroundColor(isOverdue(due) && !item.isCompleted ? MMColors.recording : MMColors.warning)
                        }

                        Button {
                            selectedMeeting = meeting
                        } label: {
                            Text(meeting.title)
                                .font(MMTypography.caption2)
                                .foregroundColor(MMColors.primary)
                                .lineLimit(1)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(MMColors.primaryLight)
                                .cornerRadius(4)
                        }
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Data

    private var allItems: [(item: ActionItem, meeting: Meeting)] {
        meetingService.allActionItems
    }

    private var filteredItems: [(item: ActionItem, meeting: Meeting)] {
        var result = allItems

        // Filter by owner type
        switch filterMode {
        case .all: break
        case .mine: result = result.filter { $0.item.isMine }
        case .others: result = result.filter { !$0.item.isMine }
        }

        // Filter by completion
        switch showCompletedFilter {
        case .all: break
        case .pending: result = result.filter { !$0.item.isCompleted }
        case .completed: result = result.filter { $0.item.isCompleted }
        }

        // Filter by person
        if let owner = ownerFilter {
            result = result.filter { $0.item.owner == owner }
        }

        // Sort: overdue first, then by due date, then by meeting date
        return result.sorted { a, b in
            let aOverdue = isOverdue(a.item.dueDate) && !a.item.isCompleted
            let bOverdue = isOverdue(b.item.dueDate) && !b.item.isCompleted
            if aOverdue != bOverdue { return aOverdue }
            if let aDue = a.item.dueDate, let bDue = b.item.dueDate {
                return aDue < bDue
            }
            return a.meeting.date > b.meeting.date
        }
    }

    private var uniqueOwners: [String] {
        let owners = Set(allItems.map { $0.item.owner }.filter { !$0.isEmpty })
        return owners.sorted()
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

    private func formattedShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    ActionItemsView()
        .environmentObject(MeetingService.shared)
}
