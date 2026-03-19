import SwiftUI

struct ProcessingView: View {
    let meeting: Meeting
    let onCancel: () -> Void

    @State private var currentStep: ProcessingStep = .compressing
    @State private var transcriptionProgress: Double = 0.0
    @State private var estimatedSeconds: Int = 20
    @State private var timer: Timer?

    enum ProcessingStep: Int, CaseIterable {
        case compressing = 0
        case transcribing = 1
        case structuring = 2
        case done = 3

        var title: String {
            switch self {
            case .compressing:  return "Compressing"
            case .transcribing: return "Transcribing"
            case .structuring:  return "Structuring"
            case .done:         return "Done"
            }
        }

        var icon: String {
            switch self {
            case .compressing:  return "arrow.down.circle"
            case .transcribing: return "waveform"
            case .structuring:  return "doc.text"
            case .done:         return "checkmark.circle.fill"
            }
        }
    }

    var body: some View {
        MMCard {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Processing Meeting")
                            .font(MMTypography.headline)
                            .foregroundColor(MMColors.textPrimary)

                        Text(meeting.title)
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if currentStep != .done {
                        Button("Cancel", action: onCancel)
                            .font(MMTypography.footnoteMedium)
                            .foregroundColor(MMColors.textSecondary)
                    }
                }

                // Steps
                HStack(spacing: 4) {
                    ForEach(ProcessingStep.allCases, id: \.rawValue) { step in
                        stepView(step)

                        if step != .done {
                            stepConnector(after: step)
                        }
                    }
                }

                // Transcription progress
                if currentStep == .transcribing {
                    VStack(spacing: 8) {
                        ProgressView(value: transcriptionProgress)
                            .tint(MMColors.primary)

                        Text("\(Int(transcriptionProgress * 100))%")
                            .font(MMTypography.monoSmall)
                            .foregroundColor(MMColors.textSecondary)
                    }
                }

                // Time estimate
                if currentStep != .done {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(MMColors.textTertiary)

                        Text("Your brief will be ready in ~\(estimatedSeconds) seconds")
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.textSecondary)
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(MMColors.success)

                        Text("Your brief is ready!")
                            .font(MMTypography.footnoteMedium)
                            .foregroundColor(MMColors.success)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .onAppear {
            simulateProcessing()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Step View

    private func stepView(_ step: ProcessingStep) -> some View {
        let isActive = step.rawValue == currentStep.rawValue
        let isCompleted = step.rawValue < currentStep.rawValue
        let isPending = step.rawValue > currentStep.rawValue

        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(
                        isCompleted ? MMColors.success :
                        isActive ? MMColors.primary :
                        MMColors.border
                    )
                    .frame(width: 28, height: 28)

                if isActive && step != .done {
                    ProgressView()
                        .scaleEffect(0.5)
                        .tint(.white)
                } else {
                    Image(systemName: isCompleted ? "checkmark" : step.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(
                            isPending ? MMColors.textTertiary : .white
                        )
                }
            }

            Text(step.title)
                .font(MMTypography.caption2)
                .foregroundColor(
                    isActive ? MMColors.primary :
                    isCompleted ? MMColors.success :
                    MMColors.textTertiary
                )
        }
        .frame(maxWidth: .infinity)
    }

    private func stepConnector(after step: ProcessingStep) -> some View {
        let isCompleted = step.rawValue < currentStep.rawValue

        return Rectangle()
            .fill(isCompleted ? MMColors.success : MMColors.border)
            .frame(height: 2)
            .frame(maxWidth: 24)
            .offset(y: -8)
    }

    // MARK: - Simulation

    private func simulateProcessing() {
        // Simulate step progression for demo
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { t in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.3)) {
                    switch currentStep {
                    case .compressing:
                        estimatedSeconds = max(0, estimatedSeconds - 1)
                        if estimatedSeconds <= 16 {
                            currentStep = .transcribing
                        }
                    case .transcribing:
                        transcriptionProgress = min(1.0, transcriptionProgress + 0.08)
                        estimatedSeconds = max(0, estimatedSeconds - 1)
                        if transcriptionProgress >= 1.0 {
                            currentStep = .structuring
                        }
                    case .structuring:
                        estimatedSeconds = max(0, estimatedSeconds - 1)
                        if estimatedSeconds <= 2 {
                            currentStep = .done
                            t.invalidate()
                        }
                    case .done:
                        t.invalidate()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        ProcessingView(
            meeting: Meeting(
                title: "Weekly Sync with Acme Corp",
                status: .processing
            ),
            onCancel: {}
        )
        Spacer()
    }
    .background(MMColors.background)
}
