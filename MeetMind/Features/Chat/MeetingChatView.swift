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
            "What action items are on me?",
            "How many tasks are related to Databricks?",
            "What were the key decisions this week?",
            "List all my pending tasks",
            "What did the customer ask me to work on?",
            "Summarize yesterday's meetings",
            "What topics came up most often?",
            "Show overdue action items"
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
                Text(message.content)
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
}

// MARK: - ViewModel

@MainActor
class MeetingChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false

    var meetingService: MeetingService?
    var todoService: TodoService?

    func sendQuery(_ query: String) async {
        let userMessage = ChatMessage(content: query, isUser: true)
        messages.append(userMessage)

        isLoading = true

        do {
            let context = buildMeetingContext(for: query)
            let response = try await GroqService.shared.chatAboutMeetings(
                query: query,
                meetingContext: context.text
            )

            let aiMessage = ChatMessage(
                content: response,
                isUser: false,
                sourceMeetings: context.meetingTitles
            )
            messages.append(aiMessage)
        } catch {
            let errorMessage = ChatMessage(
                content: "Sorry, I couldn't process that request: \(error.localizedDescription)",
                isUser: false
            )
            messages.append(errorMessage)
        }

        isLoading = false
    }

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
