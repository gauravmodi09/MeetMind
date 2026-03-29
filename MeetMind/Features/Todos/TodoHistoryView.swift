import SwiftUI

struct TodoHistoryView: View {
    @EnvironmentObject var todoService: TodoService

    @State private var selectedDate: Date = Date()
    @State private var displayedMonth: Date = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

    // All completed todos grouped by day
    private var completedByDay: [Date: [TodoItem]] {
        var dict: [Date: [TodoItem]] = [:]
        for todo in todoService.todos where todo.isCompleted {
            let day = calendar.startOfDay(for: todo.completedAt ?? todo.dueDate)
            dict[day, default: []].append(todo)
        }
        return dict
    }

    // Todos for selected day
    private var selectedDayTodos: [TodoItem] {
        let day = calendar.startOfDay(for: selectedDate)
        return (completedByDay[day] ?? [])
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    // Stats
    private var totalCompleted: Int {
        todoService.todos.filter { $0.isCompleted }.count
    }

    private var thisMonthCompleted: Int {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let end = calendar.date(byAdding: .month, value: 1, to: start)!
        return todoService.todos.filter { todo in
            guard todo.isCompleted, let completedAt = todo.completedAt else { return false }
            return completedAt >= start && completedAt < end
        }.count
    }

    private var streakDays: Int {
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        while completedByDay[checkDate] != nil {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stats row
                statsRow
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // Calendar
                calendarCard
                    .padding(.horizontal, 16)

                // Selected day detail
                selectedDayDetail
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // space for floating bar
            }
        }
        .background(MMColors.background)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(value: "\(totalCompleted)", label: "Total Done", icon: "checkmark.circle.fill", color: MMColors.success)
            statCard(value: "\(thisMonthCompleted)", label: "This Month", icon: "calendar", color: MMColors.primary)
            statCard(value: "\(streakDays)d", label: "Streak", icon: "flame.fill", color: MMColors.warning)
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(MMColors.textPrimary)
            }
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(MMColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(MMColors.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(MMColors.border, lineWidth: 1)
        )
    }

    // MARK: - Calendar Card

    private var calendarCard: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MMColors.primary)
                        .frame(width: 32, height: 32)
                }

                Spacer()

                Text(monthYearString(displayedMonth))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(MMColors.textPrimary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MMColors.primary)
                        .frame(width: 32, height: 32)
                }
            }

            // Day-of-week headers
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(MMColors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(days, id: \.self) { day in
                    if let day {
                        calendarDayCell(day)
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding(16)
        .background(MMColors.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MMColors.border, lineWidth: 1)
        )
    }

    private func calendarDayCell(_ date: Date) -> some View {
        let dayStart = calendar.startOfDay(for: date)
        let isSelected = calendar.isDate(selectedDate, inSameDayAs: date)
        let isToday = calendar.isDateInToday(date)
        let completedCount = completedByDay[dayStart]?.count ?? 0
        let hasActivity = completedCount > 0
        let isFuture = date > Date()

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isSelected || isToday ? .bold : .regular))
                    .foregroundColor(
                        isSelected ? .white :
                        isFuture ? MMColors.textTertiary.opacity(0.4) :
                        isToday ? MMColors.primary :
                        MMColors.textPrimary
                    )

                // Activity dot
                if hasActivity {
                    Circle()
                        .fill(isSelected ? Color.white : activityColor(count: completedCount))
                        .frame(width: 5, height: 5)
                } else {
                    Color.clear
                        .frame(width: 5, height: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                Group {
                    if isSelected {
                        Circle()
                            .fill(MMColors.primary)
                            .frame(width: 38, height: 38)
                    } else if isToday {
                        Circle()
                            .fill(MMColors.primaryLight)
                            .frame(width: 38, height: 38)
                    }
                }
            )
        }
        .disabled(isFuture)
    }

    private func activityColor(count: Int) -> Color {
        if count >= 5 { return MMColors.success }
        if count >= 3 { return MMColors.primary }
        return MMColors.primary.opacity(0.5)
    }

    // MARK: - Selected Day Detail

    private var selectedDayDetail: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(selectedDayHeaderString)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MMColors.textPrimary)

                Spacer()

                if !selectedDayTodos.isEmpty {
                    Text("\(selectedDayTodos.count) completed")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MMColors.success)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(MMColors.successLight)
                        .clipShape(Capsule())
                }
            }

            if selectedDayTodos.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 28))
                        .foregroundColor(MMColors.textTertiary.opacity(0.4))
                    Text("No completed tasks on this day")
                        .font(.system(size: 14))
                        .foregroundColor(MMColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                // Completed todo list
                ForEach(selectedDayTodos) { todo in
                    historyTodoRow(todo)
                }
            }
        }
        .padding(16)
        .background(MMColors.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MMColors.border, lineWidth: 1)
        )
    }

    private func historyTodoRow(_ todo: TodoItem) -> some View {
        HStack(spacing: 12) {
            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(MMColors.success)

            VStack(alignment: .leading, spacing: 3) {
                Text(todo.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MMColors.textPrimary)
                    .strikethrough(color: MMColors.textTertiary.opacity(0.5))

                HStack(spacing: 8) {
                    if let completedAt = todo.completedAt {
                        Text(completedTimeString(completedAt))
                            .font(.system(size: 11))
                            .foregroundColor(MMColors.textTertiary)
                    }

                    if let client = todo.clientTag {
                        Text(client)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(MMColors.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(MMColors.primaryLight)
                            .clipShape(Capsule())
                    }

                    // Priority indicator
                    HStack(spacing: 3) {
                        Circle()
                            .fill(priorityColor(todo.priority))
                            .frame(width: 6, height: 6)
                        Text(todo.priority.displayName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(MMColors.textTertiary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    // MARK: - Helpers

    private func daysInMonth() -> [Date?] {
        let comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        let firstOfMonth = calendar.date(from: comps)!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth)!

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            var dc = comps
            dc.day = day
            days.append(calendar.date(from: dc))
        }
        // Pad to complete the last row
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private var selectedDayHeaderString: String {
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: selectedDate)
        }
    }

    private func priorityColor(_ priority: TodoPriority) -> Color {
        switch priority {
        case .high:   return MMColors.recording
        case .medium: return MMColors.warning
        case .low:    return MMColors.textTertiary
        }
    }

    private func completedTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    TodoHistoryView()
        .environmentObject(TodoService.shared)
}
