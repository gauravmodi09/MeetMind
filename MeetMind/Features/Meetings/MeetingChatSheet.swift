import SwiftUI

/// Inline chat for a specific meeting — ask questions about this meeting's content
struct MeetingChatSheet: View {
    let meeting: Meeting
    @EnvironmentObject var meetingService: MeetingService

    @State private var messages: [(role: String, text: String)] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private let suggestions = [
        "What action items are on me?",
        "What did the customer ask me to work on?",
        "Summarize the key decisions",
        "What were the main concerns raised?",
        "What are the next steps?",
        "List all commitments made"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if messages.isEmpty {
                                suggestionsView
                                    .padding(.top, 40)
                            }

                            ForEach(Array(messages.enumerated()), id: \.offset) { index, msg in
                                chatBubble(msg.role, msg.text)
                                    .id(index)
                            }

                            if isLoading {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .tint(MMColors.primary)
                                    Text("Thinking...")
                                        .font(MMTypography.footnote)
                                        .foregroundColor(MMColors.textTertiary)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .id("loading")
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .onChange(of: messages.count) {
                        withAnimation {
                            proxy.scrollTo(messages.count - 1, anchor: .bottom)
                        }
                    }
                }

                // Input bar
                HStack(spacing: 10) {
                    TextField("Ask about this meeting...", text: $inputText)
                        .font(MMTypography.body)
                        .padding(12)
                        .background(MMColors.cardBg)
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(isInputFocused ? MMColors.primary.opacity(0.4) : MMColors.glassStroke, lineWidth: 1)
                        )
                        .focused($isInputFocused)
                        .onSubmit { sendMessage() }

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(inputText.isEmpty ? MMColors.textTertiary : MMColors.primary)
                    }
                    .disabled(inputText.isEmpty || isLoading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
            .background(MMColors.background)
            .navigationTitle("Ask about this meeting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Suggestions

    private var suggestionsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 36))
                .foregroundColor(MMColors.primary.opacity(0.3))

            Text("Ask anything about this meeting")
                .font(MMTypography.headline)
                .foregroundColor(MMColors.textSecondary)

            FlowLayout(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        inputText = suggestion
                        sendMessage()
                    } label: {
                        Text(suggestion)
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(MMColors.primary.opacity(0.08))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(MMColors.primary.opacity(0.15), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Chat Bubble

    private func chatBubble(_ role: String, _ text: String) -> some View {
        HStack {
            if role == "user" { Spacer(minLength: 60) }

            Text(text)
                .font(MMTypography.body)
                .foregroundColor(role == "user" ? .white : MMColors.textPrimary)
                .lineSpacing(4)
                .padding(14)
                .background(
                    role == "user"
                        ? MMColors.primary
                        : MMColors.cardBg
                )
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(role == "user" ? Color.clear : MMColors.glassStroke, lineWidth: 1)
                )

            if role == "assistant" { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Send Message

    private func sendMessage() {
        let query = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        messages.append(("user", query))
        inputText = ""
        isLoading = true

        Task {
            do {
                // Build context from this specific meeting
                var context = "Meeting: \(meeting.title)\n"
                context += "Date: \(meeting.date.formatted())\n"
                if let client = meeting.clientName { context += "Client: \(client)\n" }
                if let summary = meeting.briefSummary { context += "\nSummary:\n\(summary)\n" }
                if !meeting.briefDecisions.isEmpty {
                    context += "\nDecisions:\n" + meeting.briefDecisions.map { "- \($0)" }.joined(separator: "\n") + "\n"
                }
                if !meeting.briefActionItems.isEmpty {
                    context += "\nAction Items:\n" + meeting.briefActionItems.map {
                        "- \($0.text) (owner: \($0.owner), mine: \($0.isMine), due: \($0.dueDate?.formatted() ?? "not set"))"
                    }.joined(separator: "\n") + "\n"
                }
                if let transcript = meeting.rawTranscript {
                    context += "\nTranscript:\n\(transcript.prefix(3000))\n"
                }

                let answer = try await GroqService.shared.chatAboutMeetings(
                    query: query,
                    meetingContext: context
                )

                messages.append(("assistant", answer))
            } catch {
                messages.append(("assistant", "Sorry, I couldn't process that: \(error.localizedDescription)"))
            }
            isLoading = false
        }
    }
}
