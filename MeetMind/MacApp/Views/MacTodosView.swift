#if os(macOS)
import SwiftUI

struct MacTodosView: View {
    @EnvironmentObject var todoService: TodoService
    @State private var filter: TodoFilter = .pending

    enum TodoFilter: String, CaseIterable {
        case pending = "Pending"
        case completed = "Completed"
        case all = "All"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Todos")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Picker("", selection: $filter) {
                    ForEach(TodoFilter.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding(24)

            Divider()

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(filteredTodos) { todo in
                        HStack(spacing: 10) {
                            Button {
                                todoService.toggleCompletion(for: todo.id)
                            } label: {
                                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(todo.isCompleted ? Color(red: 0.063, green: 0.725, blue: 0.506) : Color(white: 0.8))
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(todo.title)
                                    .font(.system(size: 13))
                                    .strikethrough(todo.isCompleted)
                                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                                HStack(spacing: 8) {
                                    Text(todo.dueDate.formatted(date: .abbreviated, time: .omitted))
                                    if let client = todo.clientTag {
                                        Text("· \(client)")
                                    }
                                    Text("· \(todo.priority.rawValue.capitalized)")
                                        .foregroundColor(priorityColor(todo.priority))
                                }
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.98, green: 0.98, blue: 0.98)))
                    }
                }
                .padding(24)
            }
        }
        .background(Color.white)
    }

    private var filteredTodos: [TodoItem] {
        switch filter {
        case .pending:   return todoService.todos.filter { !$0.isCompleted }
        case .completed: return todoService.todos.filter { $0.isCompleted }
        case .all:       return todoService.todos
        }
    }

    private func priorityColor(_ priority: TodoPriority) -> Color {
        switch priority {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .secondary
        }
    }
}
#endif
