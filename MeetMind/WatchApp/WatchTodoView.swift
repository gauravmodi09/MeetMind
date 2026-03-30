#if os(iOS)
import SwiftUI

// MARK: - Watch-Style Todo View (MM-050)
// Compact todo list designed for Apple Watch form factor.
// Syncs completions back to iPhone via WatchConnectivityService.

/// Compact todo list view for Apple Watch. Shows today's pending items
/// with tap-to-complete and haptic feedback.
struct WatchTodoView: View {
    @StateObject private var todoService = TodoService.shared

    private let watchBackground = Color(hex: "1A1A2E")
    private let maxDisplayed = 5

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            // Header
            Text("MeetMind")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MMColors.primary)

            headerRow

            if todaysPendingTodos.isEmpty {
                emptyStateView
            } else {
                todoListView
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(watchBackground)
    }

    // MARK: - Header

    private var headerRow: some View {
        Text("\(todaysPendingTodos.count) task\(todaysPendingTodos.count == 1 ? "" : "s") today")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
    }

    // MARK: - Todo List

    private var todoListView: some View {
        VStack(spacing: 4) {
            ForEach(todaysPendingTodos.prefix(maxDisplayed)) { todo in
                WatchTodoRow(todo: todo) {
                    completeTodo(todo)
                }
            }

            if todaysPendingTodos.count > maxDisplayed {
                Text("+\(todaysPendingTodos.count - maxDisplayed) more")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .font(.system(size: 28))
                .foregroundColor(MMColors.success)
            Text("All done!")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            Spacer()
        }
    }

    // MARK: - Computed

    private var todaysPendingTodos: [TodoItem] {
        let calendar = Calendar.current
        return todoService.todos
            .filter { !$0.isCompleted && calendar.isDateInToday($0.dueDate) }
            .sorted { $0.priority.sortOrder > $1.priority.sortOrder }
    }

    // MARK: - Actions

    private func completeTodo(_ todo: TodoItem) {
        // Haptic feedback
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #elseif os(watchOS)
        WKInterfaceDevice.current().play(.success)
        #endif

        // Mark complete locally
        if let index = todoService.todos.firstIndex(where: { $0.id == todo.id }) {
            todoService.todos[index].isCompleted = true
            todoService.todos[index].completedAt = Date()
        }

        // Sync to iPhone via WatchConnectivity
        WatchConnectivityService.shared.sendTodoUpdate(
            todoId: todo.id,
            isCompleted: true
        )
    }
}

// MARK: - Watch Todo Row

/// A single todo row optimized for Watch: priority dot + truncated title, tappable.
private struct WatchTodoRow: View {
    let todo: TodoItem
    let onComplete: () -> Void

    var body: some View {
        Button {
            onComplete()
        } label: {
            HStack(spacing: 8) {
                // Priority dot
                Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)

                // Title (truncated to fit Watch screen)
                Text(todo.title)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 0)

                // Tap indicator
                Image(systemName: "circle")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.08))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var priorityColor: Color {
        switch todo.priority {
        case .high:
            return MMColors.recording
        case .medium:
            return MMColors.warning
        case .low:
            return MMColors.success
        }
    }
}

// MARK: - Watch Frame Preview Wrapper

private struct WatchTodoPreviewFrame<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(width: 198, height: 242)
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 2)
            )
    }
}

// MARK: - Previews

#Preview("Watch Todos") {
    WatchTodoPreviewFrame {
        WatchTodoView()
    }
    .padding()
    .background(Color.black)
}
#endif
