import SwiftUI

struct TodayView: View {
    @EnvironmentObject var todoService: TodoService

    @State private var showCompleted = false
    @State private var selectedTodoId: UUID?

    var body: some View {
        let todayItems = todoService.todayTodos()
        let pending = todayItems.filter { !$0.isCompleted }
        let completed = todayItems.filter { $0.isCompleted }

        Group {
            if todayItems.isEmpty {
                MMEmptyState(
                    icon: "checkmark.circle",
                    title: "All caught up!",
                    message: "You have no tasks due today. Enjoy the calm."
                )
            } else {
                List {
                    // Pending section
                    if !pending.isEmpty {
                        Section {
                            ForEach(pending) { todo in
                                TodoRow(
                                    todo: todo,
                                    onToggle: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            todoService.toggleComplete(todo)
                                            triggerHaptic()
                                        }
                                    },
                                    onReschedule: { date in
                                        todoService.reschedule(todo, to: date)
                                    },
                                    onDelete: {
                                        withAnimation {
                                            todoService.deleteTodo(todo)
                                        }
                                    },
                                    onTap: {
                                        selectedTodoId = todo.id
                                    }
                                )
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                            }
                        } header: {
                            Text("TODAY")
                                .font(MMTypography.overline)
                                .tracking(1.2)
                                .foregroundColor(MMColors.textTertiary)
                        }
                    }

                    // Completed section (MM-044: collapsed by default)
                    if !completed.isEmpty {
                        Section {
                            if showCompleted {
                                ForEach(completed) { todo in
                                    VStack(alignment: .leading, spacing: 0) {
                                        TodoRow(
                                            todo: todo,
                                            onToggle: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    todoService.toggleComplete(todo)
                                                }
                                            },
                                            onReschedule: { date in
                                                todoService.reschedule(todo, to: date)
                                            },
                                            onDelete: {
                                                withAnimation {
                                                    todoService.deleteTodo(todo)
                                                }
                                            }
                                        )

                                        // Completion timestamp
                                        if let completedAt = todo.completedAt {
                                            Text("Completed \(completedTimeString(completedAt))")
                                                .font(MMTypography.caption2)
                                                .foregroundColor(MMColors.success.opacity(0.7))
                                                .padding(.leading, 38)
                                                .padding(.bottom, 6)
                                        }
                                    }
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                                }
                            }
                        } header: {
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showCompleted.toggle()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(MMColors.success)

                                    Text("DONE")
                                        .font(MMTypography.overline)
                                        .tracking(1.2)
                                        .foregroundColor(MMColors.textTertiary)

                                    Text("(\(completed.count) completed)")
                                        .font(MMTypography.caption1)
                                        .foregroundColor(MMColors.textTertiary)

                                    Spacer()

                                    Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(MMColors.textTertiary)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .navigationDestination(isPresented: Binding(
                    get: { selectedTodoId != nil },
                    set: { if !$0 { selectedTodoId = nil } }
                )) {
                    if let todoId = selectedTodoId {
                        TodoDetailView(todoId: todoId)
                            .environmentObject(todoService)
                    }
                }
            }
        }
    }

    private func completedTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "at \(formatter.string(from: date))"
    }

    private func triggerHaptic() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }
}

// MARK: - Preview

#Preview {
    TodayView()
        .environmentObject(TodoService.shared)
}
