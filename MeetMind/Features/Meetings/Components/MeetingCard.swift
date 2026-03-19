import SwiftUI

struct MeetingCard: View {
    let meeting: Meeting
    var onCopy: (() -> Void)? = nil
    var onRetry: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onChangeClient: ((String?) -> Void)? = nil
    var availableClients: [String] = []

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 0) {
            // Left color bar
            Rectangle()
                .fill(clientColor)
                .frame(width: 3)

            HStack(spacing: 16) {
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(meeting.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(MMColors.textPrimary)
                            .lineLimit(1)

                        statusIndicator

                        if meeting.status == .complete {
                            // Simple sentiment dot based on meeting content
                            SentimentIndicator(score: estimateSentiment(meeting), showLabel: false)
                        }
                    }

                    if let clientName = meeting.clientName {
                        Text(clientName)
                            .font(MMTypography.caption1)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(clientColor.opacity(0.85))
                            .cornerRadius(8)
                    }

                    HStack(spacing: 16) {
                        Label(formattedDate, systemImage: "calendar")
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.textSecondary)

                        Label(formattedDuration, systemImage: "clock")
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.textSecondary)

                        if !meeting.briefActionItems.isEmpty {
                            Text("\(meeting.briefActionItems.count)")
                                .font(MMTypography.caption1)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(MMColors.primary)
                                .cornerRadius(8)
                        }
                    }
                }

                Spacer()

                // Right actions
                HStack(spacing: 8) {
                    if meeting.status == .failed, let onRetry {
                        Button(action: onRetry) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Retry")
                                    .font(MMTypography.caption1)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(MMColors.primary)
                            .cornerRadius(8)
                        }
                    }

                    if meeting.status == .complete, let onCopy {
                        Button(action: onCopy) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14))
                                .foregroundColor(MMColors.textTertiary)
                                .frame(width: 32, height: 32)
                                .background(MMColors.background)
                                .cornerRadius(8)
                        }
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MMColors.textTertiary)
                }
            }
            .padding(16)
        }
        .background(MMColors.cardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MMColors.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(meeting.title), \(meeting.status.displayName)\(meeting.clientName != nil ? ", client \(meeting.clientName!)" : ""), \(formattedDate), \(formattedDuration)\(!meeting.briefActionItems.isEmpty ? ", \(meeting.briefActionItems.count) action items" : "")")
        .accessibilityHint("Double-tap to view meeting details. Long press for more options.")
        .contextMenu {
            if let onChangeClient {
                Menu {
                    Button {
                        onChangeClient(nil)
                    } label: {
                        Label("General (no client)", systemImage: "folder")
                    }
                    ForEach(availableClients, id: \.self) { client in
                        Button {
                            onChangeClient(client)
                        } label: {
                            HStack {
                                Text(client)
                                if meeting.clientName == client {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Label("Change Client", systemImage: "person.2")
                }
            }

            if let onCopy {
                Button {
                    onCopy()
                } label: {
                    Label("Copy Brief", systemImage: "doc.on.doc")
                }
            }

            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete Meeting", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Status Indicator

    @State private var recordingPulse = false
    @State private var spinnerRotation: Double = 0

    @ViewBuilder
    private var statusIndicator: some View {
        switch meeting.status {
        case .complete:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(MMColors.success)
        case .processing:
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MMColors.primary)
                .rotationEffect(.degrees(spinnerRotation))
                .onAppear {
                    withAnimation(
                        .linear(duration: 1.0)
                        .repeatForever(autoreverses: false)
                    ) {
                        spinnerRotation = 360
                    }
                }
        case .recording:
            Circle()
                .fill(MMColors.recording)
                .frame(width: 8, height: 8)
                .scaleEffect(recordingPulse ? 1.3 : 0.8)
                .opacity(recordingPulse ? 0.6 : 1.0)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                    ) {
                        recordingPulse = true
                    }
                }
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(MMColors.recording)
        }
    }

    // MARK: - Helpers

    private var clientColorHex: String {
        // Derive a consistent color from the client name
        guard let name = meeting.clientName else { return "6C5CE7" }
        let colors = ["6C5CE7", "FF4757", "00CE9E", "FFA502", "2D98FF", "E84393", "00B894", "FDCB6E"]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }

    private var clientColor: Color {
        Color(hex: clientColorHex)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: meeting.date)
    }

    private func estimateSentiment(_ meeting: Meeting) -> Double {
        guard let summary = meeting.briefSummary else { return 0.0 }
        let positive = ["agreed", "success", "positive", "great", "excellent", "approved", "achieved", "progress"]
        let negative = ["blocked", "risk", "concern", "delay", "failed", "issue", "problem", "overdue"]
        let text = summary.lowercased()
        let posCount = positive.filter { text.contains($0) }.count
        let negCount = negative.filter { text.contains($0) }.count
        let total = max(posCount + negCount, 1)
        return Double(posCount - negCount) / Double(total)
    }

    private var formattedDuration: String {
        let minutes = Int(meeting.duration) / 60
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m"
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        MeetingCard(
            meeting: Meeting(
                title: "Weekly Sync with Acme Corp",
                date: Date(),
                duration: 1800,
                clientName: "Acme Corp",
                status: .complete,
                briefActionItems: [
                    ActionItem(text: "Send proposal", owner: "Me"),
                    ActionItem(text: "Review contract", owner: "John")
                ]
            ),
            onCopy: {}
        )

        MeetingCard(
            meeting: Meeting(
                title: "Product Roadmap Review",
                date: Date().addingTimeInterval(-86400),
                duration: 3600,
                clientName: "TechStart",
                status: .processing
            )
        )

        MeetingCard(
            meeting: Meeting(
                title: "Quick Standup",
                date: Date(),
                duration: 900,
                status: .complete
            )
        )
    }
    .padding()
    .background(MMColors.background)
}
