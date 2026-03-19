import SwiftUI

struct MeetingChatView: View {
    @EnvironmentObject var meetingService: MeetingService
    @EnvironmentObject var todoService: TodoService
    @StateObject private var viewModel = MeetingChatViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.messages.isEmpty {
                    emptyState
                } else {
                    messagesList
                }

                inputBar
            }
            .background(MMColors.background)
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.meetingService = meetingService
                viewModel.todoService = todoService
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                Image(systemName: "bubble.left.and.text.bubble.right")
                    .font(.system(size: 48))
                    .foregroundColor(MMColors.primary.opacity(0.6))

                Text("Ask about your meetings")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(MMColors.textPrimary)

                Text("I can search across all your meeting transcripts and briefs to answer questions.")
                    .font(.subheadline)
                    .foregroundColor(MMColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 8) {
                    Text("Try asking")
                        .font(.caption.weight(.medium))
                        .foregroundColor(MMColors.textTertiary)
                        .padding(.top, 8)

                    ForEach(suggestionChips, id: \.self) { chip in
                        Button {
                            viewModel.inputText = chip
                            sendMessage()
                        } label: {
                            Text(chip)
                                .font(.subheadline)
                                .foregroundColor(MMColors.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(MMColors.primaryLight)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var suggestionChips: [String] {
        [
            "How many meetings this week?",
            "What action items are on me?",
            "What were the key decisions?",
            "Tasks related to Databricks",
            "What did the customer ask for?",
            "Summarize yesterday's meetings",
            "Show overdue items",
            "What's my busiest client?"
        ]
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if viewModel.isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Searching meetings...")
                                .font(.caption)
                                .foregroundColor(MMColors.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .id("loading")
                    }
                }
                .padding(16)
            }
            .onChange(of: viewModel.messages.count) { _ in
                withAnimation {
                    if let last = viewModel.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isLoading) { loading in
                if loading {
                    withAnimation {
                        proxy.scrollTo("loading", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                TextField("Ask about your meetings...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .onSubmit { sendMessage() }

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(
                            viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? MMColors.textTertiary
                            : MMColors.primary
                        )
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(MMColors.cardBg)
        }
    }

    private func sendMessage() {
        let text = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        viewModel.inputText = ""
        isInputFocused = false
        Task {
            await viewModel.sendQuery(text)
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                renderMarkdownText(message.content)
                    .font(.subheadline)
                    .foregroundColor(message.isUser ? .white : MMColors.textPrimary)
                    .textSelection(.enabled)
                    .lineSpacing(3)

                if !message.sourceMeetings.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(message.sourceMeetings, id: \.self) { source in
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.system(size: 9))
                                Text(source)
                                    .font(.caption2)
                            }
                            .foregroundColor(message.isUser ? .white.opacity(0.7) : MMColors.primary)
                        }
                    }
                }
            }
            .padding(12)
            .background(message.isUser ? MMColors.primary : MMColors.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(message.isUser ? Color.clear : MMColors.border, lineWidth: 1)
            )

            if !message.isUser { Spacer(minLength: 60) }
        }
    }

    /// Parses basic markdown: **bold** and *italic* into styled Text views.
    private func renderMarkdownText(_ string: String) -> Text {
        var result = Text("")
        var remaining = string[string.startIndex...]

        while !remaining.isEmpty {
            // Look for **bold**
            if let boldStart = remaining.range(of: "**") {
                // Add text before the bold marker
                let before = remaining[remaining.startIndex..<boldStart.lowerBound]
                if !before.isEmpty {
                    result = result + renderItalic(String(before))
                }
                remaining = remaining[boldStart.upperBound...]

                // Find closing **
                if let boldEnd = remaining.range(of: "**") {
                    let boldText = String(remaining[remaining.startIndex..<boldEnd.lowerBound])
                    result = result + Text(boldText).bold()
                    remaining = remaining[boldEnd.upperBound...]
                } else {
                    // No closing **, treat as plain text
                    result = result + Text("**")
                }
            } else {
                // No more bold markers — process remaining for italic
                result = result + renderItalic(String(remaining))
                break
            }
        }

        return result
    }

    /// Parses *italic* within a text segment (after bold has been extracted).
    private func renderItalic(_ string: String) -> Text {
        var result = Text("")
        var remaining = string[string.startIndex...]

        while !remaining.isEmpty {
            if let italicStart = remaining.range(of: "*") {
                let before = remaining[remaining.startIndex..<italicStart.lowerBound]
                if !before.isEmpty {
                    result = result + Text(String(before))
                }
                remaining = remaining[italicStart.upperBound...]

                if let italicEnd = remaining.range(of: "*") {
                    let italicText = String(remaining[remaining.startIndex..<italicEnd.lowerBound])
                    result = result + Text(italicText).italic()
                    remaining = remaining[italicEnd.upperBound...]
                } else {
                    result = result + Text("*")
                }
            } else {
                result = result + Text(String(remaining))
                break
            }
        }

        return result
    }
}

// MARK: - ViewModel

@MainActor
class MeetingChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false

    var meetingService: MeetingService?
    var todoService: TodoService?

    // MARK: - Query Type Detection

    enum QueryType {
        case stats, actionItems, taskQuery, general
    }

    private func detectQueryType(_ query: String) -> QueryType {
        let q = query.lowercased()
        if q.contains("how many meeting") || q.contains("meetings this week") || q.contains("meetings today") || q.contains("total meetings") || q.contains("meeting count") || q.contains("busiest") {
            return .stats
        }
        if q.contains("action item") || q.contains("on me") || q.contains("my tasks") || q.contains("assigned to me") || q.contains("what do i need") || q.contains("my action") {
            return .actionItems
        }
        if q.contains("tasks related") || q.contains("todos about") || q.contains("how many task") || q.contains("pending task") || q.contains("overdue") {
            return .taskQuery
        }
        return .general
    }

    // MARK: - Send Query (Smart Routing)

    func sendQuery(_ query: String) async {
        let userMessage = ChatMessage(content: query, isUser: true)
        messages.append(userMessage)

        let queryType = detectQueryType(query)

        switch queryType {
        case .stats:
            messages.append(ChatMessage(content: answerStatsDirectly(query), isUser: false))
            return
        case .actionItems:
            messages.append(ChatMessage(content: answerActionItemsDirectly(query), isUser: false))
            return
        case .taskQuery:
            messages.append(ChatMessage(content: answerTaskQuery(query), isUser: false))
            return
        case .general:
            break // Fall through to LLM
        }

        // LLM for complex queries
        isLoading = true
        do {
            let context = buildMeetingContext(for: query)
            let response = try await GroqService.shared.chatAboutMeetings(query: query, meetingContext: context.text)
            messages.append(ChatMessage(content: response, isUser: false, sourceMeetings: context.meetingTitles))
        } catch {
            messages.append(ChatMessage(content: "Sorry: \(error.localizedDescription)", isUser: false))
        }
        isLoading = false
    }

    // MARK: - Direct Answer Methods

    private func answerStatsDirectly(_ query: String) -> String {
        guard let meetings = meetingService?.meetings else {
            return "No meetings available yet."
        }

        let completed = meetings.filter { $0.status == .complete }
        let cal = Calendar.current
        let now = Date()

        let today = completed.filter { cal.isDateInToday($0.date) }
        let thisWeek = completed.filter { cal.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) }
        let thisMonth = completed.filter { cal.isDate($0.date, equalTo: now, toGranularity: .month) }

        let q = query.lowercased()

        // Busiest client query
        if q.contains("busiest") {
            let clientCounts = Dictionary(grouping: completed.filter { $0.clientName != nil }, by: { $0.clientName! })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }

            if clientCounts.isEmpty {
                return "No client data available across your meetings."
            }

            var result = "Your busiest clients:\n\n"
            for (i, entry) in clientCounts.prefix(5).enumerated() {
                result += "\(i + 1). **\(entry.key)** — \(entry.value) meeting\(entry.value == 1 ? "" : "s")\n"
            }
            return result
        }

        // Meetings today
        if q.contains("today") {
            if today.isEmpty {
                return "No completed meetings today."
            }
            var result = "**\(today.count)** meeting\(today.count == 1 ? "" : "s") today:\n\n"
            let fmt = DateFormatter()
            fmt.timeStyle = .short
            for m in today {
                let client = m.clientName.map { " (*\($0)*)" } ?? ""
                result += "- **\(m.title)**\(client) at \(fmt.string(from: m.date))\n"
            }
            return result
        }

        // Meetings this week
        if q.contains("this week") || q.contains("week") {
            if thisWeek.isEmpty {
                return "No completed meetings this week."
            }
            var result = "**\(thisWeek.count)** meeting\(thisWeek.count == 1 ? "" : "s") this week:\n\n"
            let fmt = DateFormatter()
            fmt.dateFormat = "EEE, MMM d"
            for m in thisWeek.sorted(by: { $0.date < $1.date }) {
                let client = m.clientName.map { " (*\($0)*)" } ?? ""
                result += "- **\(m.title)**\(client) — \(fmt.string(from: m.date))\n"
            }
            return result
        }

        // General stats
        var result = "Meeting stats:\n\n"
        result += "- **\(today.count)** today\n"
        result += "- **\(thisWeek.count)** this week\n"
        result += "- **\(thisMonth.count)** this month\n"
        result += "- **\(completed.count)** total completed\n"

        if let latest = completed.sorted(by: { $0.date > $1.date }).first {
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            result += "\nMost recent: *\(latest.title)* on \(fmt.string(from: latest.date))"
        }

        return result
    }

    private func answerActionItemsDirectly(_ query: String) -> String {
        guard let meetings = meetingService?.meetings else {
            return "No meetings available yet."
        }

        let completed = meetings.filter { $0.status == .complete }
        let myItems = completed.flatMap { meeting in
            meeting.briefActionItems.filter { $0.isMine && !$0.isCompleted }.map { (meeting.title, $0) }
        }

        if myItems.isEmpty {
            return "No pending action items assigned to you."
        }

        var result = "**\(myItems.count)** action item\(myItems.count == 1 ? "" : "s") on you:\n\n"
        for (meetingTitle, item) in myItems {
            let due = item.dueDate.map { d in
                let fmt = DateFormatter()
                fmt.dateStyle = .short
                return " (due \(fmt.string(from: d)))"
            } ?? ""
            result += "- \(item.text)\(due)\n  from *\(meetingTitle)*\n"
        }

        return result
    }

    private func answerTaskQuery(_ query: String) -> String {
        guard let todos = todoService?.todos, !todos.isEmpty else {
            return "No tasks found."
        }

        let q = query.lowercased()

        // Overdue items
        if q.contains("overdue") {
            let overdue = todos.filter { !$0.isCompleted && $0.dueDate < Date() }
            if overdue.isEmpty {
                return "No overdue tasks — you're all caught up!"
            }
            var result = "**\(overdue.count)** overdue task\(overdue.count == 1 ? "" : "s"):\n\n"
            let fmt = DateFormatter()
            fmt.dateStyle = .short
            for task in overdue.sorted(by: { $0.dueDate < $1.dueDate }) {
                let client = task.clientTag.map { " [\($0)]" } ?? ""
                result += "- **\(task.title)**\(client) — was due \(fmt.string(from: task.dueDate))\n"
            }
            return result
        }

        // Pending tasks
        if q.contains("pending") {
            let pending = todos.filter { !$0.isCompleted }
            if pending.isEmpty {
                return "No pending tasks — all done!"
            }
            var result = "**\(pending.count)** pending task\(pending.count == 1 ? "" : "s"):\n\n"
            let fmt = DateFormatter()
            fmt.dateStyle = .short
            for task in pending.sorted(by: { $0.dueDate < $1.dueDate }).prefix(15) {
                let client = task.clientTag.map { " [\($0)]" } ?? ""
                let pri = task.priority == .high ? " !!" : ""
                result += "- **\(task.title)**\(client)\(pri) — due \(fmt.string(from: task.dueDate))\n"
            }
            if pending.count > 15 {
                result += "\n...and **\(pending.count - 15)** more"
            }
            return result
        }

        // Tasks related to keyword — extract keyword after "related to" or "about"
        let keyword: String? = {
            if let range = q.range(of: "related to ") {
                return String(q[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespaces).first
            }
            if let range = q.range(of: "about ") {
                return String(q[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespaces).first
            }
            return nil
        }()

        if let keyword = keyword, !keyword.isEmpty {
            let matched = todos.filter {
                $0.title.lowercased().contains(keyword) ||
                ($0.clientTag?.lowercased().contains(keyword) ?? false)
            }
            if matched.isEmpty {
                return "No tasks found related to **\(keyword)**."
            }
            let pending = matched.filter { !$0.isCompleted }
            let done = matched.filter { $0.isCompleted }
            var result = "**\(matched.count)** task\(matched.count == 1 ? "" : "s") related to **\(keyword)** (\(pending.count) pending, \(done.count) done):\n\n"
            let fmt = DateFormatter()
            fmt.dateStyle = .short
            for task in matched.prefix(10) {
                let status = task.isCompleted ? "~~done~~" : "pending"
                result += "- **\(task.title)** — \(status), due \(fmt.string(from: task.dueDate))\n"
            }
            return result
        }

        // Generic task count
        let pending = todos.filter { !$0.isCompleted }
        let done = todos.filter { $0.isCompleted }
        return "You have **\(todos.count)** total tasks: **\(pending.count)** pending, **\(done.count)** completed."
    }

    // MARK: - Build LLM Context

    private func buildMeetingContext(for query: String) -> (text: String, meetingTitles: [String]) {
        guard let meetings = meetingService?.meetings else {
            return ("No meetings available.", [])
        }

        let completedMeetings = meetings.filter { $0.status == .complete }
        guard !completedMeetings.isEmpty else {
            return ("No completed meetings available.", [])
        }

        let queryLower = query.lowercased()
        let queryWords = queryLower.components(separatedBy: .whitespaces).filter { $0.count > 2 }

        // Score and rank meetings by relevance to the query
        let scored = completedMeetings.map { meeting -> (Meeting, Int) in
            var score = 0
            let searchable = [
                meeting.title,
                meeting.briefSummary ?? "",
                meeting.rawTranscript ?? "",
                meeting.clientName ?? ""
            ].joined(separator: " ").lowercased()

            for word in queryWords {
                if searchable.contains(word) {
                    score += 1
                }
            }

            // Recency boost
            let daysSince = Calendar.current.dateComponents([.day], from: meeting.date, to: Date()).day ?? 0
            if daysSince <= 1 { score += 3 }
            else if daysSince <= 7 { score += 2 }
            else if daysSince <= 30 { score += 1 }

            return (meeting, score)
        }
        .sorted { $0.1 > $1.1 }

        // Take top meetings (limit context size)
        let topMeetings = Array(scored.prefix(5)).map(\.0)
        var contextParts: [String] = []
        var titles: [String] = []

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        for meeting in topMeetings {
            titles.append(meeting.title)
            var part = "--- Meeting: \(meeting.title) (\(formatter.string(from: meeting.date))) ---\n"
            if let summary = meeting.briefSummary, !summary.isEmpty {
                part += "Brief:\n\(summary)\n"
            }
            if let transcript = meeting.rawTranscript, !transcript.isEmpty {
                // Limit transcript length per meeting
                let trimmed = String(transcript.prefix(3000))
                part += "Transcript:\n\(trimmed)\n"
            }
            contextParts.append(part)
        }

        // Also include todo context
        if let todos = todoService?.todos, !todos.isEmpty {
            var todoPart = "\n--- Your Tasks ---\n"
            let tasksByClient = Dictionary(grouping: todos, by: { $0.clientTag ?? "General" })
            for (client, tasks) in tasksByClient {
                todoPart += "\n[\(client)] (\(tasks.count) tasks):\n"
                for task in tasks.prefix(10) {
                    let status = task.isCompleted ? "DONE" : "PENDING"
                    let due = task.dueDate.formatted(date: .abbreviated, time: .omitted)
                    todoPart += "  - [\(status)] \(task.title) (due: \(due), priority: \(task.priority.rawValue), source: \(task.source.rawValue))\n"
                }
            }
            todoPart += "\nTotal: \(todos.count) tasks, \(todos.filter { !$0.isCompleted }.count) pending\n"
            contextParts.append(todoPart)
        }

        return (contextParts.joined(separator: "\n\n"), titles)
    }
}

// MARK: - Preview

#Preview {
    MeetingChatView()
        .environmentObject(MeetingService.shared)
}
