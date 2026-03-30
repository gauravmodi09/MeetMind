import SwiftUI

struct TodoDetailView: View {
    @EnvironmentObject var todoService: TodoService
    @Environment(\.dismiss) private var dismiss

    let todoId: UUID
    @State private var notes: String = ""
    @State private var isEditing = false

    private var todo: TodoItem? {
        todoService.todos.first { $0.id == todoId }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let todo {
                    // Title + status
                    HStack(alignment: .top, spacing: 12) {
                        Button {
                            todoService.toggleComplete(todo)
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                        } label: {
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 24))
                                .foregroundColor(todo.isCompleted ? MMColors.success : MMColors.textTertiary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(todo.title)
                                .font(MMTypography.title3)
                                .foregroundColor(todo.isCompleted ? MMColors.textTertiary : MMColors.textPrimary)
                                .strikethrough(todo.isCompleted)

                            HStack(spacing: 8) {
                                // Priority badge
                                Text(todo.priority.displayName)
                                    .font(MMTypography.caption1)
                                    .foregroundColor(priorityColor(todo.priority))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(priorityColor(todo.priority).opacity(0.12))
                                    .clipShape(Capsule())

                                // Source badge
                                Text(todo.source.displayName)
                                    .font(MMTypography.caption1)
                                    .foregroundColor(MMColors.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(MMColors.primary.opacity(0.1))
                                    .clipShape(Capsule())

                                if let client = todo.clientTag {
                                    Text(client)
                                        .font(MMTypography.caption1)
                                        .foregroundColor(MMColors.info)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(MMColors.info.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Due date
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundColor(MMColors.textTertiary)
                        Text("Due: \(todo.dueDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(MMTypography.subheadline)
                            .foregroundColor(MMColors.textSecondary)
                    }
                    .padding(.horizontal, 20)

                    // Divider
                    Rectangle()
                        .fill(MMColors.divider)
                        .frame(height: 1)
                        .padding(.horizontal, 20)

                    // Notes section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("NOTES")
                                .font(MMTypography.overline)
                                .tracking(1.2)
                                .foregroundColor(MMColors.textTertiary)

                            Spacer()

                            if !notes.isEmpty {
                                Button {
                                    isEditing.toggle()
                                } label: {
                                    Text(isEditing ? "Done" : "Edit")
                                        .font(MMTypography.footnoteMedium)
                                        .foregroundColor(MMColors.primary)
                                }
                            }
                        }

                        if notes.isEmpty && !isEditing {
                            Button {
                                isEditing = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "note.text.badge.plus")
                                        .foregroundColor(MMColors.primary)
                                    Text("Add notes...")
                                        .font(MMTypography.subheadline)
                                        .foregroundColor(MMColors.textTertiary)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(MMColors.cardBg)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(MMColors.glassStroke, lineWidth: 1)
                                )
                            }
                        } else {
                            TextEditor(text: $notes)
                                .font(MMTypography.body)
                                .foregroundColor(MMColors.textPrimary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 120)
                                .padding(14)
                                .background(MMColors.cardBg)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(
                                            isEditing ? MMColors.primary.opacity(0.4) : MMColors.glassStroke,
                                            lineWidth: 1
                                        )
                                )
                                .disabled(!isEditing)
                                .onTapGesture {
                                    if !isEditing { isEditing = true }
                                }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Created info
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text("Created \(todo.createdAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(MMTypography.caption1)
                    }
                    .foregroundColor(MMColors.textTertiary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Delete button
                    Button(role: .destructive) {
                        todoService.deleteTodo(todo)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Task")
                        }
                        .font(MMTypography.subheadline)
                        .foregroundColor(MMColors.recording)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(MMColors.recording.opacity(0.08))
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                } else {
                    Text("Task not found")
                        .foregroundColor(MMColors.textTertiary)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(MMColors.background)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            // Load saved notes
            notes = UserDefaults.standard.string(forKey: "todo_notes_\(todoId.uuidString)") ?? ""
        }
        .onChange(of: notes) { _, newValue in
            // Auto-save notes
            UserDefaults.standard.set(newValue, forKey: "todo_notes_\(todoId.uuidString)")
        }
    }

    private func priorityColor(_ priority: TodoPriority) -> Color {
        switch priority {
        case .high: return MMColors.recording
        case .medium: return MMColors.warning
        case .low: return MMColors.info
        }
    }
}
