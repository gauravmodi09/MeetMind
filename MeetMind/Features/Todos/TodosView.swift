import SwiftUI
import AVFoundation

struct TodosView: View {
    @EnvironmentObject var todoService: TodoService

    enum TodoTab: String, CaseIterable {
        case today = "Today"
        case upcoming = "Upcoming"
        case all = "All"
        case history = "History"
    }

    @State private var selectedTab: TodoTab = .today
    @State private var showVoiceCapture = false
    @State private var showTextEntry = false

    // Inline voice recording states
    @State private var isVoiceRecording = false
    @State private var isVoiceProcessing = false
    @State private var voiceRecorder: AVAudioRecorder?
    @State private var voiceTimer: Timer?
    @State private var voiceDuration: TimeInterval = 0
    @State private var voicePulse = false

    // All tab filters
    @State private var clientFilter: String?
    @State private var priorityFilter: TodoPriority?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Glass segmented control
                    glassSegmentedControl
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                    // Tab content
                    switch selectedTab {
                    case .today:
                        TodayView()
                    case .upcoming:
                        UpcomingView()
                    case .all:
                        AllTodosView(
                            clientFilter: $clientFilter,
                            priorityFilter: $priorityFilter
                        )
                    case .history:
                        TodoHistoryView()
                    }
                }
                .background(MMColors.background)

                // Floating action bar with glass blur
                floatingActionBar
            }
            .navigationTitle("Todos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 4) {
                        if todoService.pendingCount > 0 {
                            Text("\(todoService.pendingCount)")
                                .font(MMTypography.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(MMColors.primary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showVoiceCapture) {
            VoiceTodoCaptureView()
                .environmentObject(todoService)
        }
        .sheet(isPresented: $showTextEntry) {
            TextTodoEntryView()
                .environmentObject(todoService)
        }
        .onReceive(NotificationCenter.default.publisher(for: .autoShowTextTodo)) { _ in
            showTextEntry = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .autoStartVoiceTodo)) { _ in
            startInlineRecording()
        }
    }

    // MARK: - Glass Segmented Control

    private var glassSegmentedControl: some View {
        HStack(spacing: 4) {
            ForEach(TodoTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue.uppercased())
                        .font(MMTypography.overline)
                        .tracking(0.8)
                        .foregroundColor(selectedTab == tab ? .white : MMColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedTab == tab {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(MMColors.primary)
                                        .shadow(color: MMColors.primary.opacity(0.3), radius: 6, x: 0, y: 2)
                                } else {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.clear)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(MMColors.glassStroke, lineWidth: 1)
                )
        )
    }

    // MARK: - Floating Action Bar

    private var floatingActionBar: some View {
        VStack(spacing: 0) {
            // Inline recording state
            if isVoiceRecording {
                inlineRecordingBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if isVoiceProcessing {
                inlineProcessingBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                // Normal action buttons
                HStack(spacing: 16) {
                    // Voice capture button
                    Button {
                        startInlineRecording()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Voice")
                                .font(MMTypography.footnoteMedium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(MMColors.recording)
                        .cornerRadius(25)
                        .shadow(color: MMColors.recording.opacity(0.5), radius: 12, x: 0, y: 4)
                        .shadow(color: MMColors.recording.opacity(0.3), radius: 4, x: 0, y: 2)
                    }

                    // Text add button
                    Button {
                        showTextEntry = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .bold))
                            Text("Add Task")
                                .font(MMTypography.footnoteMedium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(MMColors.primary)
                        .cornerRadius(25)
                        .shadow(color: MMColors.primary.opacity(0.4), radius: 10, x: 0, y: 4)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(MMColors.glassStroke, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: -4)
        )
        .padding(.bottom, 8)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isVoiceRecording)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isVoiceProcessing)
    }

    // MARK: - Inline Recording Bar

    private var inlineRecordingBar: some View {
        HStack(spacing: 16) {
            // Pulsing red dot
            Circle()
                .fill(MMColors.recording)
                .frame(width: 12, height: 12)
                .scaleEffect(voicePulse ? 1.3 : 1.0)
                .opacity(voicePulse ? 0.6 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: voicePulse)

            // Timer
            Text(voiceFormattedDuration)
                .font(MMTypography.monoMedium)
                .foregroundColor(.white)
                .fixedSize()

            Text("Listening...")
                .font(MMTypography.footnoteMedium)
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)

            Spacer(minLength: 4)

            // Stop button
            Button {
                stopInlineRecordingAndProcess()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("Done")
                        .font(MMTypography.footnoteMedium)
                        .fixedSize()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(MMColors.recording)
                .cornerRadius(20)
                .fixedSize()
            }

            // Cancel
            Button {
                cancelInlineRecording()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Inline Processing Bar

    private var inlineProcessingBar: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(MMColors.primary)

            Text("Processing your voice...")
                .font(MMTypography.footnoteMedium)
                .foregroundColor(.white.opacity(0.7))

            Spacer()
        }
    }

    // MARK: - Inline Voice Recording Logic

    private func startInlineRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            return
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("voice_todo_\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            voiceRecorder = try AVAudioRecorder(url: url, settings: settings)
            voiceRecorder?.record()
            isVoiceRecording = true
            voicePulse = true
            voiceDuration = 0

            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            voiceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                Task { @MainActor in
                    voiceDuration += 1
                    if voiceDuration >= 120 { // 2 min max
                        stopInlineRecordingAndProcess()
                    }
                }
            }
        } catch { }
    }

    private func stopInlineRecordingAndProcess() {
        let url = voiceRecorder?.url
        voiceTimer?.invalidate()
        voiceTimer = nil
        voiceRecorder?.stop()
        voicePulse = false
        isVoiceRecording = false
        isVoiceProcessing = true

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        Task {
            guard let fileURL = url else {
                isVoiceProcessing = false
                return
            }

            do {
                print("[VoiceTodo] Transcribing audio...")
                let result = try await GroqService.shared.transcribeAudio(fileURL: fileURL)
                print("[VoiceTodo] Transcript: \(result.text)")

                let parsed = try await GroqService.shared.parseTodoFromVoice(transcript: result.text)
                print("[VoiceTodo] Parsed: task=\(parsed.task), date=\(parsed.dueDate ?? "nil")")

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dueDate = parsed.dueDate.flatMap { dateFormatter.date(from: $0) } ?? Date()
                let priority = TodoPriority(rawValue: parsed.priority?.lowercased() ?? "medium") ?? .medium

                todoService.createTodo(
                    title: parsed.task,
                    dueDate: dueDate,
                    priority: priority,
                    clientTag: nil,
                    source: .voice
                )

                print("[VoiceTodo] Task created: \(parsed.task)")
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                print("[VoiceTodo] ERROR: \(error)")
                showVoiceCapture = true
            }

            isVoiceProcessing = false
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private func cancelInlineRecording() {
        let url = voiceRecorder?.url
        voiceTimer?.invalidate()
        voiceTimer = nil
        voiceRecorder?.stop()
        voicePulse = false
        isVoiceRecording = false
        if let url { try? FileManager.default.removeItem(at: url) }
    }

    private var voiceFormattedDuration: String {
        let m = Int(voiceDuration) / 60
        let s = Int(voiceDuration) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Upcoming View (MM-040)

struct UpcomingView: View {
    @EnvironmentObject var todoService: TodoService
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())

    private let calendar = Calendar.current

    private var next7Days: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }

    private var groupedByDay: [Date: [TodoItem]] {
        let groups = todoService.upcomingTodos()
        var dict: [Date: [TodoItem]] = [:]
        for group in groups {
            dict[calendar.startOfDay(for: group.date)] = group.todos
        }
        return dict
    }

    var body: some View {
        VStack(spacing: 0) {
            // Horizontal calendar strip
            calendarStrip
                .padding(.vertical, 12)
                .background(
                    MMColors.cardBg
                        .overlay(
                            Rectangle()
                                .fill(MMColors.glassStroke)
                                .frame(height: 1),
                            alignment: .bottom
                        )
                )
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)

            // Tasks grouped by day
            List {
                ForEach(next7Days, id: \.self) { day in
                    let dayTodos = groupedByDay[day] ?? []
                    Section {
                        if dayTodos.isEmpty {
                            HStack {
                                Spacer()
                                Text("Nothing planned")
                                    .font(MMTypography.footnote)
                                    .foregroundColor(MMColors.textTertiary)
                                    .italic()
                                    .padding(.vertical, 12)
                                Spacer()
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                        } else {
                            ForEach(dayTodos) { todo in
                                NavigationLink(destination: TodoDetailView(todoId: todo.id).environmentObject(todoService)) {
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
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                            }
                        }
                    } header: {
                        HStack {
                            Text(sectionHeader(for: day).uppercased())
                                .font(MMTypography.overline)
                                .tracking(1.2)
                                .foregroundColor(MMColors.textTertiary)
                            Spacer()
                            let count = (groupedByDay[day] ?? []).count
                            if count > 0 {
                                Text("\(count) task\(count == 1 ? "" : "s")")
                                    .font(MMTypography.caption2)
                                    .foregroundColor(MMColors.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(MMColors.primaryLight)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .refreshable {
                todoService.loadTodos()
            }
        }
    }

    // MARK: - Calendar Strip

    private var calendarStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(next7Days, id: \.self) { day in
                        let isToday = calendar.isDateInToday(day)
                        let isSelected = calendar.isDate(day, inSameDayAs: selectedDay)
                        let taskCount = (groupedByDay[day] ?? []).count

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDay = day
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Text(dayOfWeekLabel(for: day))
                                    .font(MMTypography.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(isSelected ? .white : MMColors.textTertiary)

                                Text("\(calendar.component(.day, from: day))")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(isSelected ? .white : MMColors.textPrimary)

                                if taskCount > 0 {
                                    Circle()
                                        .fill(isSelected ? Color.white : MMColors.primary)
                                        .frame(width: 6, height: 6)
                                } else {
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: 6, height: 6)
                                }
                            }
                            .frame(width: 48, height: 72)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? MMColors.primary : (isToday ? MMColors.primaryLight : Color.clear))
                            )
                        }
                        .id(day)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Helpers

    private func dayOfWeekLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private func sectionHeader(for date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - All Todos View (MM-041)

enum TodoSortOption: String, CaseIterable {
    case date = "Date"
    case priority = "Priority"
    case client = "Client"
}

struct AllTodosView: View {
    @EnvironmentObject var todoService: TodoService
    @Binding var clientFilter: String?
    @Binding var priorityFilter: TodoPriority?
    @State private var sortOption: TodoSortOption = .priority
    @State private var showCompleted = false

    private var filtered: [TodoItem] {
        todoService.allTodos(clientFilter: clientFilter, priorityFilter: priorityFilter)
    }

    private var pendingTodos: [TodoItem] {
        sortTodos(filtered.filter { !$0.isCompleted })
    }

    private var completedTodos: [TodoItem] {
        filtered.filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private func sortTodos(_ todos: [TodoItem]) -> [TodoItem] {
        switch sortOption {
        case .date:
            return todos.sorted { $0.dueDate < $1.dueDate }
        case .priority:
            return todos.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
        case .client:
            return todos.sorted { ($0.clientTag ?? "zzz") < ($1.clientTag ?? "zzz") }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Priority chips: All | High | Medium | Low
                    priorityChipButton(label: "All", priority: nil)
                    ForEach(TodoPriority.allCases, id: \.self) { p in
                        priorityChipButton(label: p.displayName, priority: p)
                    }

                    Divider()
                        .frame(height: 20)
                        .padding(.horizontal, 4)

                    // Client filter dropdown
                    Menu {
                        Button("All Clients") { clientFilter = nil }
                        ForEach(todoService.allClientTags, id: \.self) { tag in
                            Button(tag) { clientFilter = tag }
                        }
                    } label: {
                        filterChip(
                            text: clientFilter ?? "Client",
                            isActive: clientFilter != nil,
                            icon: "person.2"
                        )
                    }

                    Divider()
                        .frame(height: 20)
                        .padding(.horizontal, 4)

                    // Sort options
                    Menu {
                        ForEach(TodoSortOption.allCases, id: \.self) { option in
                            Button {
                                sortOption = option
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        filterChip(
                            text: "Sort: \(sortOption.rawValue)",
                            isActive: true,
                            icon: "arrow.up.arrow.down"
                        )
                    }

                    if clientFilter != nil || priorityFilter != nil {
                        Button {
                            clientFilter = nil
                            priorityFilter = nil
                        } label: {
                            Text("Clear")
                                .font(MMTypography.caption1)
                                .foregroundColor(MMColors.recording)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            // List
            if pendingTodos.isEmpty && completedTodos.isEmpty {
                MMEmptyState(
                    icon: "tray",
                    title: "No matching todos",
                    message: "Try adjusting your filters."
                )
            } else {
                List {
                    // Pending tasks
                    if !pendingTodos.isEmpty {
                        Section {
                            ForEach(pendingTodos) { todo in
                                NavigationLink(destination: TodoDetailView(todoId: todo.id).environmentObject(todoService)) {
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
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                            }
                        }
                    }

                    // Completed section (collapsible)
                    if !completedTodos.isEmpty {
                        Section {
                            if showCompleted {
                                ForEach(completedTodos) { todo in
                                    NavigationLink(destination: TodoDetailView(todoId: todo.id).environmentObject(todoService)) {
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
                                    }
                                    .buttonStyle(.plain)
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
                                    Text("COMPLETED")
                                        .font(MMTypography.overline)
                                        .tracking(1.2)
                                        .foregroundColor(MMColors.textTertiary)

                                    Text("\(completedTodos.count)")
                                        .font(MMTypography.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(MMColors.success)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(MMColors.successLight)
                                        .cornerRadius(4)

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
            }
        }
    }

    // MARK: - Priority Chip

    @ViewBuilder
    private func priorityChipButton(label: String, priority: TodoPriority?) -> some View {
        let isActive = priorityFilter == priority
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                priorityFilter = priority
            }
        } label: {
            Text(label)
                .font(MMTypography.caption1)
                .fontWeight(.semibold)
                .foregroundColor(isActive ? .white : MMColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isActive ? MMColors.primary : MMColors.cardBg)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isActive ? Color.clear : MMColors.border, lineWidth: 1)
                )
        }
    }

    // MARK: - Filter Chip

    @ViewBuilder
    private func filterChip(text: String, isActive: Bool, icon: String? = nil) -> some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(MMTypography.caption1)
                .fontWeight(.medium)
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .semibold))
        }
        .foregroundColor(isActive ? .white : MMColors.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isActive ? MMColors.primary : MMColors.cardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isActive ? Color.clear : MMColors.border, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    TodosView()
        .environmentObject(TodoService.shared)
}
