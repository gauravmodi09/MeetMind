import SwiftUI

struct TodoRow: View {
    let todo: TodoItem
    let onToggle: () -> Void
    let onReschedule: (Date) -> Void
    let onDelete: () -> Void

    @State private var showDatePicker = false
    @State private var rescheduleDate = Date()
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 12) {
            // Priority dot with glow
            Circle()
                .fill(priorityColor)
                .frame(width: 10, height: 10)
                .shadow(color: priorityColor.opacity(0.6), radius: 4, x: 0, y: 0)
                .accessibilityLabel("\(todo.priority.displayName) priority")

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(todo.isCompleted ? MMColors.textTertiary : MMColors.textPrimary)
                    .strikethrough(todo.isCompleted, color: MMColors.textTertiary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let client = todo.clientTag {
                        // Colored glass pill for client tag
                        Text(client)
                            .font(MMTypography.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "6C5CE7"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "6C5CE7").opacity(0.12))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color(hex: "6C5CE7").opacity(0.2), lineWidth: 0.5)
                                    )
                            )
                    }

                    Text(formattedTime)
                        .font(MMTypography.caption1)
                        .foregroundColor(MMColors.textTertiary)

                    if todo.source == .meeting {
                        sourceBadge(text: "from meeting", color: MMColors.primary)
                    } else if todo.source == .voice {
                        sourceBadge(text: "voice", color: MMColors.info)
                    }

                    if let recurrence = todo.recurrence {
                        // Success green pill for recurrence
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 9, weight: .semibold))
                            Text(recurrence.rawValue)
                                .font(MMTypography.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(MMColors.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(MMColors.successLight)
                        )
                        .accessibilityLabel("Repeats \(recurrence.rawValue)")
                    }
                }
            }

            Spacer()

            // Notes indicator
            if hasNotes {
                Image(systemName: "note.text")
                    .font(.system(size: 11))
                    .foregroundColor(MMColors.primary.opacity(0.5))
            }

            // Chevron for navigation
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(MMColors.textTertiary.opacity(0.4))
                .padding(.trailing, 4)

            // Checkbox with spring animation
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(todo.isCompleted ? MMColors.success : MMColors.border, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if todo.isCompleted {
                        Circle()
                            .fill(MMColors.success)
                            .frame(width: 24, height: 24)
                            .transition(.scale.combined(with: .opacity))

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.6), value: todo.isCompleted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(todo.isCompleted ? "Mark as incomplete" : "Mark as complete")
            .accessibilityHint("Double-tap to toggle completion")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .opacity(todo.isCompleted ? 0.4 : 1.0)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(MMColors.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(MMColors.glassStroke, lineWidth: 1)
                )
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(todo.title), \(todo.priority.displayName) priority\(todo.isCompleted ? ", completed" : ""), due \(formattedTime)\(todo.clientTag != nil ? ", client \(todo.clientTag!)" : "")")
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                showDatePicker = true
                rescheduleDate = todo.dueDate
            } label: {
                Label("Reschedule", systemImage: "calendar")
            }
            .tint(MMColors.warning)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !todo.isCompleted {
                Button {
                    onToggle()
                } label: {
                    Label("Complete", systemImage: "checkmark.circle.fill")
                }
                .tint(MMColors.success)
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                DatePicker(
                    "Reschedule to",
                    selection: $rescheduleDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Reschedule")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showDatePicker = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            onReschedule(rescheduleDate)
                            showDatePicker = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Helpers

    private var hasNotes: Bool {
        let notes = UserDefaults.standard.string(forKey: "todo_notes_\(todo.id.uuidString)") ?? ""
        return !notes.isEmpty
    }

    private var priorityColor: Color {
        switch todo.priority {
        case .high:   return MMColors.recording
        case .medium: return MMColors.warning
        case .low:    return MMColors.textTertiary
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: todo.dueDate)
    }

    @ViewBuilder
    private func sourceBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(MMTypography.caption2)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .cornerRadius(4)
    }
}

// MARK: - Preview

#Preview {
    List {
        TodoRow(
            todo: TodoItem(
                title: "Send Databricks cost report to Maulik",
                dueDate: Date(),
                priority: .high,
                clientTag: "Databricks",
                source: .meeting
            ),
            onToggle: {},
            onReschedule: { _ in },
            onDelete: {}
        )

        TodoRow(
            todo: TodoItem(
                title: "Review Q3 launch matrix",
                dueDate: Date(),
                priority: .medium,
                clientTag: "General",
                source: .manual,
                isCompleted: true,
                completedAt: Date()
            ),
            onToggle: {},
            onReschedule: { _ in },
            onDelete: {}
        )

        TodoRow(
            todo: TodoItem(
                title: "Book flight to Chicago",
                dueDate: Date(),
                priority: .low,
                source: .voice
            ),
            onToggle: {},
            onReschedule: { _ in },
            onDelete: {}
        )
    }
    .listStyle(.plain)
}
