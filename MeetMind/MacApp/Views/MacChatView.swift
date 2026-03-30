#if os(macOS)
import SwiftUI

struct MacChatView: View {
    @EnvironmentObject var meetingService: MeetingService
    @State private var messageText = ""
    @State private var messages: [(String, Bool)] = [] // (text, isUser)

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("AI Chat")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
            }
            .padding(24)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { _, msg in
                        HStack {
                            if msg.1 { Spacer() }
                            Text(msg.0)
                                .font(.system(size: 13))
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(msg.1 ? MMColors.primary : Color(red: 0.95, green: 0.95, blue: 0.97))
                                )
                                .foregroundColor(msg.1 ? .white : .primary)
                            if !msg.1 { Spacer() }
                        }
                    }
                }
                .padding(24)
            }

            Divider()

            HStack(spacing: 8) {
                TextField("Ask about your meetings...", text: $messageText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit { sendMessage() }

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(messageText.isEmpty ? .secondary : MMColors.primary)
                }
                .buttonStyle(.plain)
                .disabled(messageText.isEmpty)
            }
            .padding(16)
        }
        .background(Color.white)
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        let text = messageText
        messages.append((text, true))
        messageText = ""
        messages.append(("I'll analyze your meetings and get back to you. (AI integration pending)", false))
    }
}
#endif
