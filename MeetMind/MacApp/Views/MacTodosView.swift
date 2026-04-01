#if os(macOS)
import SwiftUI

// MARK: - Main View

struct MacTodosView: View {
    @EnvironmentObject var todoService: TodoService
    @State private var selectedTab: TodoTab = .today
    @State private var priorityFilter: TodoPriority? = nil
    @State private var showAddSheet = false
    @State private var hoveredTodoId: UUID?

    enum TodoTab: String, CaseIterable {
        case today     = "Today"
        case upcoming  = "Upcoming"
        case all       = "All"
        case completed = "Completed"

        var systemImage: String {
            switch self {
            case .today:     return "sun.max"
            case .upcoming:  return "calendar"
            case .all:       return "list.bullet"
            case .completed: return "checkmark.circle"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            tabBar
            Divider()
            content
        }
        .background(MMColors.backgroundElevated)
        .sheet(isPresented: $showAddSheet) {
            AddTodoSheet(todoService: todoService)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Tasks")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(MMColors.textPrimary)
                HStack(spacing: 6) {
                    Text("\(todoService.pendingCount) pending")
                        .foregroundColor(MMColors.textTertiary)
                    Text("·")
                        .foregroundColor(MMColors.border)
                    Text("\(completedCount) completed")
                        .foregroundColor(MMColors.textTertiary)
                    if overdueCount > 0 {
                        Text("·")
                            .foregroundColor(MMColors.border)
                        Text("\(overdueCount) overdue")
                            .foregroundColor(MMColors.recording)
                    }
                }
                .font(.system(size: 12))
            }

            Spacer()

            // Priority filter dropdown
            Menu {
                Button("All Priorities") { priorityFilter = nil }
                Divider()
                Button {
                    priorityFilter = .high
                } label: {
                    Label("High", systemImage: "circle.fill")
                }
                Button {
                    priorityFilter = .medium
                } label: {
                    Label("Medium", systemImage: "circle.fill")
                }
                Button {
                    priorityFilter = .low
                } label: {
                    Label("Low", systemImage: "circle.fill")
                }
            } label: {
                HStack(spacing: 5) {
                    if let p = priorityFilter {
                        Circle()
                            .fill(priorityColor(p))
                            .frame(width: 7, height: 7)
                        Text(p.rawValue.capitalized)
                    } else {
                        Image(systemName: "line.3.horizontal.decrease")
                        Text("Priority")
                    }
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(priorityFilter != nil ? MMColors.primary : MMColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(priorityFilter != nil ? MMColors.primaryLight : MMColors.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(priorityFilter != nil ? MMColors.primary.opacity(0.3) : MMColors.border, lineWidth: 1)
                        )
                )
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            // Add Task button
            Button {
                showAddSheet = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Add Task")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(MMColors.primary)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 14)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(TodoTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 0)
    }

    private func tabButton(_ tab: TodoTab) -> some View {
        let isSelected = selectedTab == tab
        let count = tabCount(for: tab)

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(isSelected ? MMColors.primary : MMColors.textTertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? MMColors.primaryLight : MMColors.background)
                        )
                }
            }
            .foregroundColor(isSelected ? MMColors.primary : MMColors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                VStack {
                    Spacer()
                    if isSelected {
                        Rectangle()
                            .fill(MMColors.primary)
                            .frame(height: 2)
                            .cornerRadius(1)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 2)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .today:
            todayContent
        case .upcoming:
            upcomingContent
        case .all:
            allContent
        case .completed:
            completedContent
        }
    }

    // MARK: - Today Content

    private var todayContent: some View {
        let overdue = applyPriorityFilter(todoService.todos.filter { !$0.isCompleted && isOverdue($0.dueDate) })
        let dueToday = applyPriorityFilter(todoService.todos.filter { !$0.isCompleted && Calendar.current.isDateInToday($0.dueDate) })

        return Group {
            if overdue.isEmpty && dueToday.isEmpty {
                emptyState(
                    icon: "sun.max",
                    title: "All clear for today",
                    subtitle: "No tasks due today. Great job staying on top of things."
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if !overdue.isEmpty {
                            sectionHeader(title: "Overdue", color: MMColors.recording, count: overdue.count)
                            ForEach(overdue) { todo in
                                todoRow(todo)
                            }
                        }
                        if !dueToday.isEmpty {
                            sectionHeader(title: "Due Today", color: MMColors.textSecondary, count: dueToday.count)
                            ForEach(dueToday) { todo in
                                todoRow(todo)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    // MARK: - Upcoming Content

    private var upcomingContent: some View {
        let groups = upcomingGroups
        return Group {
            if groups.isEmpty {
                emptyState(
                    icon: "calendar",
                    title: "Nothing coming up",
                    subtitle: "No tasks due in the next 7 days."
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(groups, id: \.label) { group in
                            sectionHeader(title: group.label, color: MMColors.textSecondary, count: group.items.count)
                            ForEach(group.items) { todo in
                                todoRow(todo)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    // MARK: - All Content

    private var allContent: some View {
        let todos = applyPriorityFilter(todoService.todos.filter { !$0.isCompleted })
        return Group {
            if todos.isEmpty {
                emptyState(
                    icon: "checklist",
                    title: "No pending tasks",
                    subtitle: "Add a task or record a meeting to auto-generate action items."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(todos) { todo in
                            todoRow(todo)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    // MARK: - Completed Content

    private var completedContent: some View {
        let todos = applyPriorityFilter(todoService.todos.filter { $0.isCompleted })
        return Group {
            if todos.isEmpty {
                emptyState(
                    icon: "checkmark.circle",
                    title: "No completed tasks",
                    subtitle: "Tasks you complete will appear here."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(todos) { todo in
                            todoRow(todo)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, color: Color, count: Int) -> some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(color)
                .frame(width: 3, height: 13)
                .cornerRadius(1.5)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
                .textCase(.uppercase)
                .tracking(0.5)
            Text("(\(count))")
                .font(.system(size: 11))
                .foregroundColor(color.opacity(0.6))
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 16)
        .padding(.bottom, 6)
    }

    // MARK: - Todo Row

    private func todoRow(_ todo: TodoItem) -> some View {
        let isHovered = hoveredTodoId == todo.id

        return HStack(spacing: 12) {
            // Completion toggle
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    todoService.toggleCompletion(for: todo.id)
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(todo.isCompleted ? MMColors.success : priorityColor(todo.priority).opacity(0.5), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if todo.isCompleted {
                        Circle()
                            .fill(MMColors.success)
                            .frame(width: 20, height: 20)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .fill(priorityColor(todo.priority).opacity(0.08))
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .buttonStyle(.plain)

            // Main content
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    // Priority dot
                    Circle()
                        .fill(priorityColor(todo.priority))
                        .frame(width: 7, height: 7)

                    // Title
                    Text(todo.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(todo.isCompleted ? MMColors.textTertiary : MMColors.textPrimary)
                        .strikethrough(todo.isCompleted, color: MMColors.textTertiary)
                        .lineLimit(1)

                    // Recurrence
                    if todo.recurrence != nil {
                        Image(systemName: "repeat")
                            .font(.system(size: 10))
                            .foregroundColor(MMColors.textTertiary)
                    }
                }

                // Metadata row
                HStack(spacing: 8) {
                    // Due date
                    HStack(spacing: 3) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))
                        Text(smartDateLabel(todo.dueDate))
                            .font(.system(size: 11))
                    }
                    .foregroundColor(dueDateColor(todo))

                    // Priority label
                    Text(todo.priority.rawValue.capitalized)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(priorityColor(todo.priority))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(priorityColor(todo.priority).opacity(0.1))
                        )

                    // Source badge
                    sourceBadge(todo.source)

                    // Client tag
                    if let client = todo.clientTag {
                        HStack(spacing: 3) {
                            Image(systemName: "building.2")
                                .font(.system(size: 9))
                            Text(client)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(MMColors.textTertiary)
                    }
                }
            }

            Spacer()

            // Hover actions
            if isHovered {
                HStack(spacing: 6) {
                    Button {
                        todoService.deleteTodo(todo)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(MMColors.recording)
                            .padding(5)
                            .background(
                                Circle()
                                    .fill(MMColors.recordingLight)
                            )
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? MMColors.background : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isHovered ? MMColors.border : Color.clear, lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onHover { h in
            withAnimation(.easeInOut(duration: 0.12)) {
                hoveredTodoId = h ? todo.id : nil
            }
        }
        .contextMenu {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    todoService.toggleCompletion(for: todo.id)
                }
            } label: {
                Label(todo.isCompleted ? "Mark as Pending" : "Mark as Complete",
                      systemImage: todo.isCompleted ? "circle" : "checkmark.circle")
            }

            Divider()

            Menu("Change Priority") {
                Button {
                    todoService.deleteTodo(todo)
                    todoService.createTodo(
                        title: todo.title,
                        dueDate: todo.dueDate,
                        priority: .high,
                        clientTag: todo.clientTag,
                        source: todo.source
                    )
                } label: {
                    Label("High", systemImage: "circle.fill")
                }
                Button {
                    todoService.deleteTodo(todo)
                    todoService.createTodo(
                        title: todo.title,
                        dueDate: todo.dueDate,
                        priority: .medium,
                        clientTag: todo.clientTag,
                        source: todo.source
                    )
                } label: {
                    Label("Medium", systemImage: "circle.fill")
                }
                Button {
                    todoService.deleteTodo(todo)
                    todoService.createTodo(
                        title: todo.title,
                        dueDate: todo.dueDate,
                        priority: .low,
                        clientTag: todo.clientTag,
                        source: todo.source
                    )
                } label: {
                    Label("Low", systemImage: "circle.fill")
                }
            }

            Divider()

            Button(role: .destructive) {
                todoService.deleteTodo(todo)
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
    }

    // MARK: - Source Badge

    @ViewBuilder
    private func sourceBadge(_ source: TodoSource) -> some View {
        switch source {
        case .meeting:
            HStack(spacing: 3) {
                Image(systemName: "waveform")
                    .font(.system(size: 9))
                Text("Meeting")
                    .font(.system(size: 11))
            }
            .foregroundColor(MMColors.primary)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Capsule().fill(MMColors.primaryLight))
        case .voice:
            HStack(spacing: 3) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 9))
                Text("Voice")
                    .font(.system(size: 11))
            }
            .foregroundColor(MMColors.info)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Capsule().fill(MMColors.infoLight))
        case .manual:
            EmptyView()
        }
    }

    // MARK: - Empty State

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(MMColors.background)
                    .frame(width: 64, height: 64)
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(MMColors.textTertiary.opacity(0.5))
            }
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MMColors.textSecondary)
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(MMColors.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
            if selectedTab != .completed {
                Button {
                    showAddSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Add Task")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(MMColors.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(MMColors.primaryLight)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 40)
    }

    // MARK: - Helpers

    private func applyPriorityFilter(_ todos: [TodoItem]) -> [TodoItem] {
        guard let p = priorityFilter else { return todos }
        return todos.filter { $0.priority == p }
    }

    private func isOverdue(_ date: Date) -> Bool {
        date < Calendar.current.startOfDay(for: Date())
    }

    private var overdueCount: Int {
        todoService.todos.filter { !$0.isCompleted && isOverdue($0.dueDate) }.count
    }

    private var completedCount: Int {
        todoService.todos.filter { $0.isCompleted }.count
    }

    private func tabCount(for tab: TodoTab) -> Int {
        let cal = Calendar.current
        switch tab {
        case .today:
            return todoService.todos.filter { !$0.isCompleted && (cal.isDateInToday($0.dueDate) || isOverdue($0.dueDate)) }.count
        case .upcoming:
            return upcomingGroups.reduce(0) { $0 + $1.items.count }
        case .all:
            return todoService.todos.filter { !$0.isCompleted }.count
        case .completed:
            return todoService.todos.filter { $0.isCompleted }.count
        }
    }

    private struct DayGroup {
        let label: String
        let items: [TodoItem]
    }

    private var upcomingGroups: [DayGroup] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let in7Days = cal.date(byAdding: .day, value: 7, to: today)!
        let todos = applyPriorityFilter(
            todoService.todos.filter { !$0.isCompleted && !cal.isDateInToday($0.dueDate) && !isOverdue($0.dueDate) && $0.dueDate < in7Days }
        )
        var dict: [(label: String, date: Date, items: [TodoItem])] = []
        for todo in todos.sorted(by: { $0.dueDate < $1.dueDate }) {
            let dayStart = cal.startOfDay(for: todo.dueDate)
            if let idx = dict.firstIndex(where: { cal.isDate($0.date, inSameDayAs: dayStart) }) {
                dict[idx].items.append(todo)
            } else {
                let label: String
                if cal.isDateInTomorrow(todo.dueDate) {
                    label = "Tomorrow"
                } else {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "EEEE, MMM d"
                    label = formatter.string(from: todo.dueDate)
                }
                dict.append((label: label, date: dayStart, items: [todo]))
            }
        }
        return dict.map { DayGroup(label: $0.label, items: $0.items) }
    }

    private func smartDateLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if isOverdue(date) {
            let days = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: Date())).day ?? 0
            return days == 1 ? "Yesterday" : "\(days)d overdue"
        }
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInTomorrow(date) { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func dueDateColor(_ todo: TodoItem) -> Color {
        if todo.isCompleted { return MMColors.textTertiary }
        if isOverdue(todo.dueDate) { return MMColors.recording }
        if Calendar.current.isDateInToday(todo.dueDate) { return MMColors.warning }
        return MMColors.textTertiary
    }

    private func priorityColor(_ priority: TodoPriority) -> Color {
        switch priority {
        case .high:   return MMColors.recording
        case .medium: return MMColors.warning
        case .low:    return MMColors.textTertiary
        }
    }
}

// MARK: - Add Todo Sheet

private struct AddTodoSheet: View {
    let todoService: TodoService
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var dueDate = Date()
    @State private var priority: TodoPriority = .medium
    @State private var clientTag = ""
    @FocusState private var titleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Sheet header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("New Task")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(MMColors.textPrimary)
                    Text("Add a task to your list")
                        .font(.system(size: 12))
                        .foregroundColor(MMColors.textTertiary)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MMColors.textTertiary)
                        .padding(7)
                        .background(Circle().fill(MMColors.background))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .padding(.bottom, 18)

            Divider()

            VStack(alignment: .leading, spacing: 20) {
                // Title field
                VStack(alignment: .leading, spacing: 6) {
                    fieldLabel("Task Title")
                    TextField("What needs to be done?", text: $title)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .focused($titleFocused)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(MMColors.background)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(titleFocused ? MMColors.primary.opacity(0.5) : MMColors.border, lineWidth: 1)
                                )
                        )
                }

                // Due date + priority row
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel("Due Date")
                        DatePicker("", selection: $dueDate, displayedComponents: .date)
                            .labelsHidden()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(MMColors.background)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(MMColors.border, lineWidth: 1)
                                    )
                            )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel("Priority")
                        Picker("", selection: $priority) {
                            Text("Low").tag(TodoPriority.low)
                            Text("Medium").tag(TodoPriority.medium)
                            Text("High").tag(TodoPriority.high)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 190)
                    }
                }

                // Client tag (optional)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        fieldLabel("Client Tag")
                        Text("(optional)")
                            .font(.system(size: 10))
                            .foregroundColor(MMColors.textTertiary)
                    }
                    TextField("e.g. Acme Corp", text: $clientTag)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(MMColors.background)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(MMColors.border, lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer()

            Divider()

            // Footer buttons
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(MMColors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(MMColors.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(MMColors.border, lineWidth: 1)
                        )
                )

                Button("Add Task") {
                    guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    todoService.createTodo(
                        title: title.trimmingCharacters(in: .whitespaces),
                        dueDate: dueDate,
                        priority: priority,
                        clientTag: clientTag.isEmpty ? nil : clientTag.trimmingCharacters(in: .whitespaces),
                        source: .manual
                    )
                    dismiss()
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(title.trimmingCharacters(in: .whitespaces).isEmpty ? MMColors.primary.opacity(0.4) : MMColors.primary)
                )
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 440, height: 380)
        .background(MMColors.backgroundElevated)
        .onAppear { titleFocused = true }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(MMColors.textTertiary)
            .textCase(.uppercase)
            .tracking(0.4)
    }
}

#endif
