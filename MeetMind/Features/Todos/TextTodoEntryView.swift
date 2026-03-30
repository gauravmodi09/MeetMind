import SwiftUI

struct TextTodoEntryView: View {
    @EnvironmentObject var todoService: TodoService
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var dueDate = Date()
    @State private var priority: TodoPriority = .medium
    @State private var selectedClient: String?
    @State private var selectedRecurrence: TodoRecurrence?
    @State private var detectedDate: Date?
    @State private var detectedDateLabel: String?
    @State private var hasManuallySetDate = false
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Title field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Task")
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.textTertiary)

                        TextField("What needs to be done?", text: $title, axis: .vertical)
                            .font(MMTypography.body)
                            .lineLimit(1...4)
                            .padding(14)
                            .background(MMColors.cardBg)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        isTitleFocused ? MMColors.primary : MMColors.border,
                                        lineWidth: isTitleFocused ? 2 : 1
                                    )
                            )
                            .focused($isTitleFocused)
                            .onChange(of: title) { _, newValue in
                                guard !hasManuallySetDate else { return }
                                if let parsed = NaturalDateParser.parseDate(from: newValue) {
                                    detectedDate = parsed.date
                                    detectedDateLabel = parsed.label
                                    dueDate = parsed.date
                                } else {
                                    detectedDate = nil
                                    detectedDateLabel = nil
                                }
                            }

                        // Detected date badge
                        if let label = detectedDateLabel {
                            Button {
                                hasManuallySetDate = true
                                detectedDate = nil
                                detectedDateLabel = nil
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Due: \(label)")
                                        .font(MMTypography.caption1)
                                        .fontWeight(.medium)
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(MMColors.textTertiary)
                                }
                                .foregroundColor(MMColors.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(MMColors.primaryLight)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            .animation(.easeInOut(duration: 0.2), value: detectedDateLabel)
                            .accessibilityLabel("Detected due date: \(label)")
                            .accessibilityHint("Tap to dismiss and set date manually")
                        }
                    }

                    // Date picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Due Date")
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.textTertiary)

                        DatePicker(
                            "",
                            selection: $dueDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(MMColors.cardBg)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(MMColors.border, lineWidth: 1)
                        )
                        .onChange(of: dueDate) { _, _ in
                            // If user manually picks a date, stop auto-detecting
                            if isTitleFocused == false {
                                hasManuallySetDate = true
                            }
                        }
                    }

                    // Priority selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority")
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.textTertiary)

                        HStack(spacing: 10) {
                            ForEach(TodoPriority.allCases, id: \.self) { p in
                                Button {
                                    priority = p
                                } label: {
                                    Text(p.displayName)
                                        .font(MMTypography.footnoteMedium)
                                        .foregroundColor(
                                            priority == p ? .white : MMColors.textSecondary
                                        )
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            priority == p
                                                ? priorityColor(p)
                                                : MMColors.background
                                        )
                                        .cornerRadius(22)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 22)
                                                .stroke(
                                                    priority == p ? Color.clear : MMColors.border,
                                                    lineWidth: 1
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(p.displayName) priority")
                                .accessibilityValue(priority == p ? "Selected" : "Not selected")
                                .accessibilityHint("Double-tap to set priority to \(p.displayName)")
                            }
                        }
                    }

                    // Recurrence picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Repeat (optional)")
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.textTertiary)

                        Menu {
                            Button("None") { selectedRecurrence = nil }
                            ForEach(TodoRecurrence.allCases, id: \.self) { r in
                                Button(r.rawValue) { selectedRecurrence = r }
                            }
                        } label: {
                            HStack {
                                if let recurrence = selectedRecurrence {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(MMColors.primary)
                                    Text(recurrence.rawValue)
                                        .font(MMTypography.body)
                                        .foregroundColor(MMColors.textPrimary)
                                } else {
                                    Text("No repeat")
                                        .font(MMTypography.body)
                                        .foregroundColor(MMColors.textTertiary)
                                }

                                Spacer()

                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(MMColors.textTertiary)
                            }
                            .padding(14)
                            .background(MMColors.cardBg)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(MMColors.border, lineWidth: 1)
                            )
                        }
                        .accessibilityLabel("Recurrence")
                        .accessibilityValue(selectedRecurrence?.rawValue ?? "None")
                        .accessibilityHint("Double-tap to set how often this task repeats")
                    }

                    // Client tag
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Client Tag (optional)")
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.textTertiary)

                        Menu {
                            Button("None") { selectedClient = nil }
                            ForEach(todoService.allClientTags, id: \.self) { tag in
                                Button(tag) { selectedClient = tag }
                            }
                        } label: {
                            HStack {
                                Text(selectedClient ?? "Select client...")
                                    .font(MMTypography.body)
                                    .foregroundColor(
                                        selectedClient != nil
                                            ? MMColors.textPrimary
                                            : MMColors.textTertiary
                                    )

                                Spacer()

                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(MMColors.textTertiary)
                            }
                            .padding(14)
                            .background(MMColors.cardBg)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(MMColors.border, lineWidth: 1)
                            )
                        }
                        .accessibilityLabel("Client tag")
                        .accessibilityValue(selectedClient ?? "None selected")
                        .accessibilityHint("Double-tap to select a client tag for this task")
                    }

                    Spacer(minLength: 24)

                    // Add button
                    MMButton("Add Task", icon: "plus.circle.fill") {
                        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

                        todoService.createTodo(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            dueDate: dueDate,
                            priority: priority,
                            clientTag: selectedClient,
                            source: .manual,
                            recurrence: selectedRecurrence
                        )

                        #if os(iOS)
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        #endif
                        dismiss()
                    }
                    .opacity(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                }
                .padding(24)
            }
            .background(MMColors.background)
            .navigationTitle("New Task")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                isTitleFocused = true
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Helpers

    private func priorityColor(_ p: TodoPriority) -> Color {
        switch p {
        case .high:   return MMColors.recording
        case .medium: return MMColors.warning
        case .low:    return MMColors.info
        }
    }
}

// MARK: - Natural Language Date Parser

struct NaturalDateParser {
    struct ParsedDate {
        let date: Date
        let label: String
    }

    /// Parse a natural language date from text input.
    /// Handles phrases like "tomorrow", "next week", "by Friday", "before March 25", etc.
    static func parseDate(from text: String) -> ParsedDate? {
        let lowered = text.lowercased()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"

        // Check explicit keywords first
        if lowered.contains("today") {
            let date = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: today) ?? today
            return ParsedDate(date: date, label: "Today")
        }

        if lowered.contains("tomorrow") {
            if let date = calendar.date(byAdding: .day, value: 1, to: today) {
                let withTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
                return ParsedDate(date: withTime, label: "Tomorrow, \(formatter.string(from: date))")
            }
        }

        if lowered.contains("next week") {
            // Next Monday
            if let nextMonday = nextWeekday(.monday, from: today, skipThisWeek: true) {
                let withTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: nextMonday) ?? nextMonday
                return ParsedDate(date: withTime, label: formatter.string(from: nextMonday))
            }
        }

        // "this Friday", "by Friday", "on Thursday", etc.
        let dayNames: [(String, Int)] = [
            ("sunday", 1), ("monday", 2), ("tuesday", 3), ("wednesday", 4),
            ("thursday", 5), ("friday", 6), ("saturday", 7)
        ]

        for (name, weekday) in dayNames {
            let patterns = ["by \(name)", "on \(name)", "this \(name)", "before \(name)", "\(name)"]
            for pattern in patterns {
                if lowered.contains(pattern) {
                    let skipThisWeek = lowered.contains("next \(name)")
                    if let target = nextWeekdayNumber(weekday, from: today, skipThisWeek: skipThisWeek) {
                        let withTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: target) ?? target
                        return ParsedDate(date: withTime, label: formatter.string(from: target))
                    }
                }
            }
        }

        // Try NSDataDetector for explicit dates like "March 25", "3/25", etc.
        if let detected = detectDateWithNSDataDetector(from: text) {
            // Only use if the date is in the future
            if detected > Date() {
                return ParsedDate(date: detected, label: formatter.string(from: detected))
            }
        }

        return nil
    }

    private static func nextWeekday(_ day: Weekday, from date: Date, skipThisWeek: Bool) -> Date? {
        let calendar = Calendar.current
        let target: Int
        switch day {
        case .monday: target = 2
        case .friday: target = 6
        }
        return nextWeekdayNumber(target, from: date, skipThisWeek: skipThisWeek)
    }

    private enum Weekday {
        case monday, friday
    }

    private static func nextWeekdayNumber(_ weekday: Int, from date: Date, skipThisWeek: Bool) -> Date? {
        let calendar = Calendar.current
        let current = calendar.component(.weekday, from: date)
        var daysAhead = weekday - current
        if daysAhead <= 0 || skipThisWeek {
            daysAhead += 7
        }
        return calendar.date(byAdding: .day, value: daysAhead, to: date)
    }

    private static func detectDateWithNSDataDetector(from text: String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, options: [], range: range)
        return matches.first?.date
    }
}

// MARK: - Preview

#Preview {
    TextTodoEntryView()
        .environmentObject(TodoService.shared)
}
