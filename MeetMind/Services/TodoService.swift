import Foundation
import Combine

/// Manages todo items: CRUD, completion, filtering, and pending count for tab badge.
/// In-memory storage for now; Core Data persistence will be added later.
@MainActor
class TodoService: ObservableObject {
    static let shared = TodoService()

    @Published var todos: [TodoItem] = []

    private let calendar = Calendar.current

    // MARK: - Init with Sample Data

    private init() {
        loadTodos()
    }

    // MARK: - CRUD

    func createTodo(
        title: String,
        dueDate: Date,
        priority: TodoPriority,
        clientTag: String?,
        source: TodoSource,
        recurrence: TodoRecurrence? = nil
    ) {
        let todo = TodoItem(
            title: title,
            dueDate: dueDate,
            priority: priority,
            clientTag: clientTag,
            source: source,
            recurrence: recurrence
        )
        todos.append(todo)
    }

    func createFromVoice(transcript: String) async throws {
        let parsed = try await GroqService.shared.parseTodoFromVoice(transcript: transcript)

        var dueDate = Date()
        if let dateString = parsed.dueDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let parsed = formatter.date(from: dateString) {
                dueDate = parsed
            }
        }

        var priority: TodoPriority = .medium
        if let p = parsed.priority {
            priority = TodoPriority(rawValue: p.lowercased()) ?? .medium
        }

        let todo = TodoItem(
            title: parsed.task,
            dueDate: dueDate,
            priority: priority,
            source: .voice
        )
        todos.append(todo)

        // Save detailed notes if AI extracted them
        if let notes = parsed.notes, !notes.isEmpty {
            UserDefaults.standard.set(notes, forKey: "todo_notes_\(todo.id.uuidString)")
        }
    }

    func createFromMeetingActions(_ actions: [ActionItem], meetingId: UUID) {
        for action in actions where action.isMine {
            let todo = TodoItem(
                title: action.text,
                dueDate: action.dueDate ?? Date(),
                priority: .high,
                source: .meeting,
                sourceMeetingId: meetingId
            )
            todos.append(todo)
        }
    }

    func toggleComplete(_ todo: TodoItem) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[index].isCompleted.toggle()
        todos[index].completedAt = todos[index].isCompleted ? Date() : nil

        // If completing a recurring todo, auto-create the next occurrence
        if todos[index].isCompleted, let recurrence = todos[index].recurrence {
            let nextDate = recurrence.nextDueDate(from: todos[index].dueDate)
            let nextTodo = TodoItem(
                title: todos[index].title,
                dueDate: nextDate,
                priority: todos[index].priority,
                clientTag: todos[index].clientTag,
                source: todos[index].source,
                sourceMeetingId: todos[index].sourceMeetingId,
                recurrence: recurrence
            )
            todos.append(nextTodo)
        }
    }

    func reschedule(_ todo: TodoItem, to date: Date) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[index].dueDate = date
    }

    func deleteTodo(_ todo: TodoItem) {
        todos.removeAll { $0.id == todo.id }
    }

    // MARK: - Load / Seed

    func loadTodos() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today),
              let nextWeek = calendar.date(byAdding: .day, value: 5, to: today)
        else { return }

        todos = [
            TodoItem(
                title: "Send Meyer POC presentation to David",
                dueDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today) ?? today,
                priority: .high,
                clientTag: "Meyer",
                source: .meeting
            ),
            TodoItem(
                title: "Follow up on Databricks table access",
                dueDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow) ?? tomorrow,
                priority: .high,
                clientTag: "Databricks",
                source: .meeting
            ),
            TodoItem(
                title: "Register for Databricks Data Engineer certification",
                dueDate: nextWeek,
                priority: .medium,
                source: .voice
            ),
            TodoItem(
                title: "Prepare agenda for next sprint planning",
                dueDate: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow,
                priority: .medium,
                source: .manual
            ),
        ]
    }

    // MARK: - Filtered Views

    func todayTodos() -> [TodoItem] {
        todos
            .filter { calendar.isDateInToday($0.dueDate) }
            .sorted { $0.priority.sortOrder < $1.priority.sortOrder }
    }

    func upcomingTodos() -> [(date: Date, todos: [TodoItem])] {
        let today = calendar.startOfDay(for: Date())
        guard let endDate = calendar.date(byAdding: .day, value: 7, to: today) else { return [] }

        let upcoming = todos
            .filter { !$0.isCompleted && $0.dueDate >= today && $0.dueDate < endDate }
            .sorted { $0.dueDate < $1.dueDate }

        let grouped = Dictionary(grouping: upcoming) { todo in
            calendar.startOfDay(for: todo.dueDate)
        }

        return grouped
            .sorted { $0.key < $1.key }
            .map { (date: $0.key, todos: $0.value.sorted { $0.priority.sortOrder < $1.priority.sortOrder }) }
    }

    func allTodos(clientFilter: String? = nil, priorityFilter: TodoPriority? = nil) -> [TodoItem] {
        var result = todos

        if let client = clientFilter, !client.isEmpty {
            result = result.filter { $0.clientTag == client }
        }

        if let priority = priorityFilter {
            result = result.filter { $0.priority == priority }
        }

        return result.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
    }

    var pendingCount: Int {
        todayTodos().filter { !$0.isCompleted }.count
    }

    // MARK: - Helpers

    var allClientTags: [String] {
        Array(Set(todos.compactMap { $0.clientTag })).sorted()
    }
}
