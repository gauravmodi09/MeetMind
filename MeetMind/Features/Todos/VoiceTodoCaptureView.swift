import SwiftUI
import AVFoundation

struct VoiceTodoCaptureView: View {
    @EnvironmentObject var todoService: TodoService
    @Environment(\.dismiss) private var dismiss

    enum CaptureState {
        case idle
        case recording
        case processing
        case parsed
        case error(String)
    }

    @State private var captureState: CaptureState = .idle
    @State private var transcribedText = ""
    @State private var parsedTask = ""
    @State private var parsedDate = Date()
    @State private var parsedPriority: TodoPriority = .medium
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingTimer: Timer?
    @State private var recordingDuration: TimeInterval = 0
    @State private var pulseAnimation = false
    @State private var waveformLevels: [CGFloat] = Array(repeating: 0.1, count: 20)

    private let maxDuration: TimeInterval = 120 // 2 minutes

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // State-dependent content
                switch captureState {
                case .idle:
                    idleView
                case .recording:
                    recordingView
                case .processing:
                    processingView
                case .parsed:
                    parsedResultView
                case .error(let message):
                    errorView(message)
                }

                Spacer()

                // Action buttons
                actionButtons
            }
            .padding(24)
            .background(MMColors.background)
            .navigationTitle("Voice Todo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        stopRecording()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .onDisappear {
            stopRecording()
        }
    }

    // MARK: - State Views

    private var idleView: some View {
        VStack(spacing: 16) {
            micButton(isRecording: false)

            Text("Speak your task...")
                .font(MMTypography.headline)
                .foregroundColor(MMColors.textSecondary)

            Text("Tap the mic to start recording")
                .font(MMTypography.caption1)
                .foregroundColor(MMColors.textTertiary)
        }
    }

    private var recordingView: some View {
        VStack(spacing: 20) {
            micButton(isRecording: true)

            // Waveform visualization
            HStack(spacing: 3) {
                ForEach(0..<20, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(MMColors.recording.opacity(0.7))
                        .frame(width: 4, height: max(4, waveformLevels[index] * 40))
                        .animation(
                            .easeInOut(duration: 0.15),
                            value: waveformLevels[index]
                        )
                }
            }
            .frame(height: 44)

            Text(formattedDuration)
                .font(MMTypography.mono)
                .foregroundColor(MMColors.recording)

            Text("Listening... Tap to stop")
                .font(MMTypography.caption1)
                .foregroundColor(MMColors.textTertiary)
        }
    }

    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(MMColors.primary)

            Text("Processing your voice...")
                .font(MMTypography.headline)
                .foregroundColor(MMColors.textSecondary)
        }
    }

    private var parsedResultView: some View {
        VStack(spacing: 20) {
            // Transcribed text
            VStack(alignment: .leading, spacing: 6) {
                Text("Transcribed")
                    .font(MMTypography.caption1)
                    .foregroundColor(MMColors.textTertiary)

                Text(transcribedText)
                    .font(MMTypography.subheadline)
                    .foregroundColor(MMColors.textSecondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(MMColors.background)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(MMColors.border, lineWidth: 1)
                    )
            }

            // Parsed fields
            VStack(spacing: 14) {
                // Task
                VStack(alignment: .leading, spacing: 6) {
                    Text("Task")
                        .font(MMTypography.caption1)
                        .foregroundColor(MMColors.textTertiary)

                    TextField("Task description", text: $parsedTask)
                        .font(MMTypography.body)
                        .padding(12)
                        .background(MMColors.cardBg)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(MMColors.border, lineWidth: 1)
                        )
                }

                // Date
                VStack(alignment: .leading, spacing: 6) {
                    Text("Date")
                        .font(MMTypography.caption1)
                        .foregroundColor(MMColors.textTertiary)

                    DatePicker(
                        "",
                        selection: $parsedDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(MMColors.cardBg)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(MMColors.border, lineWidth: 1)
                    )
                }

                // Priority
                VStack(alignment: .leading, spacing: 6) {
                    Text("Priority")
                        .font(MMTypography.caption1)
                        .foregroundColor(MMColors.textTertiary)

                    HStack(spacing: 10) {
                        ForEach(TodoPriority.allCases, id: \.self) { priority in
                            Button {
                                parsedPriority = priority
                            } label: {
                                Text(priority.displayName)
                                    .font(MMTypography.footnoteMedium)
                                    .foregroundColor(
                                        parsedPriority == priority ? .white : MMColors.textSecondary
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        parsedPriority == priority
                                            ? prioritySelectedColor(priority)
                                            : MMColors.background
                                    )
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                parsedPriority == priority
                                                    ? Color.clear
                                                    : MMColors.border,
                                                lineWidth: 1
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(MMColors.warning)

            Text("Something went wrong")
                .font(MMTypography.headline)
                .foregroundColor(MMColors.textPrimary)

            Text(message)
                .font(MMTypography.subheadline)
                .foregroundColor(MMColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Mic Button

    @ViewBuilder
    private func micButton(isRecording: Bool) -> some View {
        Button {
            if isRecording {
                stopAndProcess()
            } else {
                startRecording()
            }
        } label: {
            ZStack {
                // Pulse rings
                if isRecording {
                    Circle()
                        .fill(MMColors.recording.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: pulseAnimation
                        )

                    Circle()
                        .fill(MMColors.recording.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseAnimation ? 1.15 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                            value: pulseAnimation
                        )
                }

                Circle()
                    .fill(isRecording ? MMColors.recording : MMColors.recording.opacity(0.9))
                    .frame(width: 80, height: 80)
                    .shadow(color: MMColors.recording.opacity(0.3), radius: 10, x: 0, y: 4)

                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        switch captureState {
        case .idle:
            EmptyView()

        case .recording:
            EmptyView()

        case .processing:
            EmptyView()

        case .parsed:
            VStack(spacing: 12) {
                MMButton("Add Task", icon: "plus.circle.fill") {
                    todoService.createTodo(
                        title: parsedTask,
                        dueDate: parsedDate,
                        priority: parsedPriority,
                        clientTag: nil,
                        source: .voice
                    )
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    dismiss()
                }

                MMButton("Discard", style: .ghost) {
                    dismiss()
                }
            }

        case .error:
            MMButton("Try Again", icon: "arrow.clockwise") {
                captureState = .idle
            }
        }
    }

    // MARK: - Recording Logic

    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            captureState = .error("Could not access microphone: \(error.localizedDescription)")
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
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            captureState = .recording
            pulseAnimation = true
            recordingDuration = 0

            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                Task { @MainActor in
                    recordingDuration += 0.1

                    // Update waveform
                    audioRecorder?.updateMeters()
                    let level = audioRecorder?.averagePower(forChannel: 0) ?? -160
                    let normalized = CGFloat(max(0, min(1, (level + 50) / 50)))

                    waveformLevels.removeFirst()
                    waveformLevels.append(normalized)

                    if recordingDuration >= maxDuration {
                        stopAndProcess()
                    }
                }
            }
        } catch {
            captureState = .error("Recording failed: \(error.localizedDescription)")
        }
    }

    private func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioRecorder?.stop()
        pulseAnimation = false
    }

    private func stopAndProcess() {
        let url = audioRecorder?.url
        stopRecording()
        captureState = .processing

        Task {
            guard let fileURL = url else {
                captureState = .error("No recording file found.")
                return
            }

            do {
                // Transcribe
                let result = try await GroqService.shared.transcribeAudio(fileURL: fileURL)
                transcribedText = result.text

                // Parse with AI
                let parsed = try await GroqService.shared.parseTodoFromVoice(transcript: result.text)

                parsedTask = parsed.task

                if let dateString = parsed.dueDate {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    parsedDate = formatter.date(from: dateString) ?? Date()
                } else {
                    parsedDate = Date()
                }

                parsedPriority = TodoPriority(rawValue: parsed.priority?.lowercased() ?? "medium") ?? .medium

                captureState = .parsed
            } catch {
                captureState = .error(error.localizedDescription)
            }

            // Cleanup temp file
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    // MARK: - Helpers

    private var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func prioritySelectedColor(_ priority: TodoPriority) -> Color {
        switch priority {
        case .high:   return MMColors.recording
        case .medium: return MMColors.warning
        case .low:    return MMColors.info
        }
    }
}

// MARK: - Preview

#Preview {
    VoiceTodoCaptureView()
        .environmentObject(TodoService.shared)
}
