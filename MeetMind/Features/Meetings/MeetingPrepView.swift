import SwiftUI

struct MeetingPrepView: View {
    let clientName: String?
    let onStartRecording: () -> Void
    let onDismiss: () -> Void

    @State private var context: MeetingPrepContext = .empty
    @State private var appeared = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(MMColors.textTertiary)
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    if context.hasContext {
                        lastMeetingCard
                        if !context.pendingActionItems.isEmpty {
                            actionItemsCard
                        }
                        if !context.unresolvedBlockers.isEmpty {
                            blockersCard
                        }
                    } else {
                        noContextCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }

            startButton
        }
        .background(MMColors.background)
        .onAppear {
            context = MeetingPrepService.shared.prepareContext(for: clientName)
            withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Meeting Prep")
                    .font(MMTypography.title2)
                    .foregroundColor(MMColors.textPrimary)
                if let name = clientName, !name.isEmpty {
                    Text(name)
                        .font(MMTypography.subheadlineMedium)
                        .foregroundColor(MMColors.primary)
                }
            }
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(MMColors.textTertiary)
            }
        }
    }

    // MARK: - Last Meeting Card

    private var lastMeetingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(MMColors.primary)
                    .font(.system(size: 14, weight: .semibold))
                Text("LAST MEETING")
                    .font(MMTypography.overline)
                    .foregroundColor(MMColors.textSecondary)
                    .tracking(0.8)
            }

            if let title = context.lastMeetingTitle {
                Text(title)
                    .font(MMTypography.headline)
                    .foregroundColor(MMColors.textPrimary)
                    .lineLimit(2)
            }

            if let date = context.lastMeetingDate {
                Text(dateFormatter.string(from: date))
                    .font(MMTypography.caption1)
                    .foregroundColor(MMColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(MMColors.cardBg)
                // Purple accent bar on left edge
                RoundedRectangle(cornerRadius: 14)
                    .fill(MMColors.primary)
                    .frame(width: 3)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(MMColors.border, lineWidth: 1)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    // MARK: - Action Items Card

    private var actionItemsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checklist")
                    .foregroundColor(MMColors.warning)
                    .font(.system(size: 14, weight: .semibold))
                Text("PENDING ACTION ITEMS")
                    .font(MMTypography.overline)
                    .foregroundColor(MMColors.textSecondary)
                    .tracking(0.8)
                Spacer()
                Text("\(context.pendingActionItems.count)")
                    .font(MMTypography.caption1Medium)
                    .foregroundColor(MMColors.warning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(MMColors.warningLight.opacity(0.6))
                    .clipShape(Capsule())
            }

            ForEach(Array(context.pendingActionItems.prefix(5))) { item in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(item.isMine ? MMColors.primary : MMColors.textTertiary)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.text)
                            .font(MMTypography.subheadline)
                            .foregroundColor(MMColors.textPrimary)
                            .lineLimit(2)
                        HStack(spacing: 6) {
                            if !item.owner.isEmpty {
                                Text(item.owner)
                                    .font(MMTypography.caption1)
                                    .foregroundColor(MMColors.textTertiary)
                            }
                            if item.isMine {
                                Text("YOU")
                                    .font(MMTypography.caption2)
                                    .foregroundColor(MMColors.primary)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(MMColors.primaryLight)
                                    .clipShape(Capsule())
                            }
                            if let due = item.dueDate {
                                Text(due, style: .date)
                                    .font(MMTypography.caption1)
                                    .foregroundColor(due < Date() ? MMColors.recording : MMColors.textTertiary)
                            }
                        }
                    }
                }
            }

            if context.pendingActionItems.count > 5 {
                Text("+ \(context.pendingActionItems.count - 5) more")
                    .font(MMTypography.caption1)
                    .foregroundColor(MMColors.textTertiary)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(MMColors.cardBg)
                RoundedRectangle(cornerRadius: 14)
                    .fill(MMColors.warning)
                    .frame(width: 3)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(MMColors.border, lineWidth: 1)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
    }

    // MARK: - Blockers Card

    private var blockersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(MMColors.recording)
                    .font(.system(size: 14, weight: .semibold))
                Text("OPEN BLOCKERS")
                    .font(MMTypography.overline)
                    .foregroundColor(MMColors.textSecondary)
                    .tracking(0.8)
            }

            ForEach(Array(context.unresolvedBlockers.enumerated()), id: \.offset) { _, blocker in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(MMColors.recording.opacity(0.7))
                        .font(.system(size: 10))
                        .padding(.top, 4)
                    Text(blocker)
                        .font(MMTypography.subheadline)
                        .foregroundColor(MMColors.textPrimary)
                        .lineLimit(3)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(MMColors.cardBg)
                RoundedRectangle(cornerRadius: 14)
                    .fill(MMColors.recording)
                    .frame(width: 3)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(MMColors.border, lineWidth: 1)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    // MARK: - No Context Card

    private var noContextCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundColor(MMColors.primary.opacity(0.6))
            Text("No previous meetings found")
                .font(MMTypography.headline)
                .foregroundColor(MMColors.textPrimary)
            Text("After your first meeting, prep context will appear here automatically.")
                .font(MMTypography.subheadline)
                .foregroundColor(MMColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(MMColors.cardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(MMColors.border, lineWidth: 1)
        )
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button(action: onStartRecording) {
            HStack(spacing: 10) {
                Image(systemName: "record.circle")
                    .font(.system(size: 18, weight: .semibold))
                Text("Start Recording")
                    .font(MMTypography.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [MMColors.primary, MMColors.primaryDark],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: MMColors.primary.opacity(0.35), radius: 12, y: 6)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
        .padding(.top, 12)
        .background(MMColors.background)
    }
}

// MARK: - Preview

#Preview {
    MeetingPrepView(
        clientName: "Meyer",
        onStartRecording: {},
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
