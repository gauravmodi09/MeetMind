import SwiftUI

struct RecordingView: View {
    @StateObject private var audioService = AudioRecordingService.shared
    @EnvironmentObject var meetingService: MeetingService

    @State private var notes: String = ""
    @State private var detectedClient: String?
    @State private var waveformLevels: [CGFloat] = Array(repeating: 0.05, count: 30)
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var showCancelConfirm = false
    @State private var showDurationWarning = false
    @State private var isNotesExpanded = false
    @State private var selectedTemplate: MeetingTemplate = .general

    // Ambient blob animation state
    @State private var blob1Offset: CGSize = CGSize(width: -80, height: -120)
    @State private var blob2Offset: CGSize = CGSize(width: 100, height: 60)
    @State private var blob3Offset: CGSize = CGSize(width: -40, height: 150)

    @FocusState private var isNotesFocused: Bool

    let onStop: (Meeting?) -> Void
    let onCancel: () -> Void

    private let barCount = 30

    var body: some View {
        ZStack {
            // Deep cinema gradient background
            LinearGradient(
                colors: [Color(hex: "050506"), Color(hex: "0A0A0F")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Ambient light blobs
            ambientBlobs

            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.top, 8)

                Spacer(minLength: 8)

                // Client badge
                if let client = detectedClient {
                    MMBadge(text: client, variant: .client("6C5CE7"))
                        .padding(.bottom, 16)
                }

                // Recording indicator
                recordingIndicator
                    .padding(.bottom, 16)

                // Timer
                Text(formattedTime)
                    .font(MMTypography.monoLarge)
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
                    .accessibilityLabel("Recording duration: \(accessibleDuration)")
                    .accessibilityAddTraits(.updatesFrequently)

                // Remaining time warning (shows after 2 hours)
                if audioService.duration >= 7200 {
                    remainingTimeIndicator
                        .padding(.bottom, 8)
                }

                // Waveform
                waveformView
                    .frame(height: 60)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
                    .accessibilityLabel("Audio waveform visualization")
                    .accessibilityHidden(true)

                // Meeting template selector
                MeetingTemplateSelector(selectedTemplate: $selectedTemplate)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                // Notes area
                notesEditor
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                // Controls
                controlButtons
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            startRecording()
            startAmbientAnimation()
        }
        .onTapGesture {
            isNotesFocused = false
        }
        .onChange(of: audioService.audioLevel) { _, newLevel in
            updateWaveform(level: CGFloat(newLevel))
        }
        .onReceive(NotificationCenter.default.publisher(for: AudioRecordingService.maxDurationWarningNotification)) { _ in
            showDurationWarning = true
        }
        .onReceive(NotificationCenter.default.publisher(for: AudioRecordingService.maxDurationReachedNotification)) { _ in
            stopAndFinish()
        }
        .alert("Cancel Recording?", isPresented: $showCancelConfirm) {
            Button("Keep Recording", role: .cancel) {}
            Button("Discard", role: .destructive) {
                discardRecording()
            }
        } message: {
            Text("Your recording will be discarded and cannot be recovered.")
        }
        .alert("Recording Limit Approaching", isPresented: $showDurationWarning) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your recording will automatically stop at 3 hours. You have about 15 minutes remaining.")
        }
    }

    // MARK: - Ambient Blobs

    private var ambientBlobs: some View {
        ZStack {
            Circle()
                .fill(MMColors.primary.opacity(0.05))
                .frame(width: 200, height: 200)
                .blur(radius: 80)
                .offset(blob1Offset)

            Circle()
                .fill(MMColors.primary.opacity(0.04))
                .frame(width: 160, height: 160)
                .blur(radius: 60)
                .offset(blob2Offset)

            Circle()
                .fill(Color(hex: "6C5CE7").opacity(0.03))
                .frame(width: 180, height: 180)
                .blur(radius: 70)
                .offset(blob3Offset)
        }
    }

    private func startAmbientAnimation() {
        withAnimation(
            .easeInOut(duration: 8)
            .repeatForever(autoreverses: true)
        ) {
            blob1Offset = CGSize(width: 60, height: 80)
        }
        withAnimation(
            .easeInOut(duration: 10)
            .repeatForever(autoreverses: true)
        ) {
            blob2Offset = CGSize(width: -80, height: -100)
        }
        withAnimation(
            .easeInOut(duration: 12)
            .repeatForever(autoreverses: true)
        ) {
            blob3Offset = CGSize(width: 70, height: -60)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                showCancelConfirm = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Cancel")
                        .font(MMTypography.subheadline)
                }
                .foregroundColor(.white.opacity(0.7))
            }
            .padding(.leading, 16)
            .accessibilityLabel("Cancel recording")
            .accessibilityHint("Double-tap to discard the current recording")

            Spacer()
        }
    }

    // MARK: - Recording Indicator

    private var recordingIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(MMColors.recording)
                .frame(width: 10, height: 10)
                .scaleEffect(pulseScale)
                .animation(
                    audioService.isPaused
                        ? .default
                        : .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: pulseScale
                )
                .onAppear {
                    pulseScale = 0.6
                }

            Text(audioService.isPaused ? "Paused" : "Recording...")
                .font(MMTypography.footnoteMedium)
                .foregroundColor(audioService.isPaused ? .white.opacity(0.5) : MMColors.recording)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(audioService.isPaused ? "Recording paused" : "Recording in progress")
    }

    // MARK: - Waveform

    private var waveformView: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: index))
                    .frame(width: 4, height: max(4, waveformLevels[index] * 80))
                    .shadow(color: MMColors.primary.opacity(0.3), radius: 4, x: 0, y: 0)
                    .animation(.easeOut(duration: 0.1), value: waveformLevels[index])
            }
        }
    }

    private func barColor(for index: Int) -> Color {
        let center = barCount / 2
        let distance = abs(index - center)
        let maxDistance = barCount / 2
        let factor = 1.0 - (Double(distance) / Double(maxDistance)) * 0.5
        return MMColors.primary.opacity(factor)
    }

    // MARK: - Notes Editor

    private var notesEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(MMColors.primary)
                    .font(.system(size: 14))

                Text("Meeting Notes")
                    .font(MMTypography.footnoteMedium)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isNotesExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isNotesExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            // Scrollable text editor
            ZStack(alignment: .topLeading) {
                // Placeholder
                if notes.isEmpty {
                    Text("Jot your thoughts during the meeting... AI will enhance them")
                        .font(MMTypography.body)
                        .foregroundColor(.white.opacity(0.25))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $notes)
                    .font(MMTypography.body)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .tint(MMColors.primary)
                    .focused($isNotesFocused)
                    .frame(minHeight: isNotesExpanded ? 140 : 70, maxHeight: isNotesExpanded ? 200 : 100)
                    .accessibilityLabel("Meeting notes")
                    .accessibilityHint("Type your notes during the meeting")
            }

            // AI hint
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                    .foregroundColor(MMColors.primary.opacity(0.7))

                Text("Your notes + AI transcript = better summary")
                    .font(MMTypography.caption2)
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isNotesFocused ? MMColors.primary.opacity(0.4) : Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isNotesFocused)
    }

    // MARK: - Remaining Time Indicator

    private var remainingTimeIndicator: some View {
        let remaining = max(0, 10800 - audioService.duration)
        let remainingMinutes = Int(remaining) / 60
        let isUrgent = remaining <= 900 // 15 minutes

        return HStack(spacing: 8) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 12))

            Text("\(remainingMinutes) min remaining")
                .font(MMTypography.caption1)
        }
        .foregroundColor(isUrgent ? MMColors.recording : MMColors.warning)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            (isUrgent ? MMColors.recording : MMColors.warning)
                .opacity(0.15)
        )
        .cornerRadius(12)
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: 40) {
            // Pause / Resume
            Button {
                if audioService.isPaused {
                    audioService.resumeRecording()
                } else {
                    audioService.pauseRecording()
                }
            } label: {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 52, height: 52)
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            .frame(width: 52, height: 52)

                        Image(systemName: audioService.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    Text(audioService.isPaused ? "Resume" : "Pause")
                        .font(MMTypography.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .accessibilityLabel(audioService.isPaused ? "Resume recording" : "Pause recording")
            .accessibilityHint("Double-tap to \(audioService.isPaused ? "resume" : "pause") the recording")

            // Stop
            Button {
                stopAndFinish()
            } label: {
                VStack(spacing: 8) {
                    ZStack {
                        // Recording-red glow shadow
                        Circle()
                            .fill(MMColors.recording.opacity(0.25))
                            .frame(width: 88, height: 88)
                            .blur(radius: 12)

                        Circle()
                            .fill(MMColors.recording)
                            .frame(width: 72, height: 72)
                            .shadow(color: MMColors.recording.opacity(0.6), radius: 16, x: 0, y: 4)
                            .shadow(color: MMColors.recording.opacity(0.3), radius: 24, x: 0, y: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white)
                            .frame(width: 22, height: 22)
                    }
                    Text("Stop")
                        .font(MMTypography.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .accessibilityLabel("Stop recording")
            .accessibilityHint("Double-tap to stop and process the recording")
        }
    }

    // MARK: - Formatted Time

    private var formattedTime: String {
        let totalSeconds = Int(audioService.duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private var accessibleDuration: String {
        let totalSeconds = Int(audioService.duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        var parts: [String] = []
        if hours > 0 { parts.append("\(hours) hour\(hours == 1 ? "" : "s")") }
        if minutes > 0 { parts.append("\(minutes) minute\(minutes == 1 ? "" : "s")") }
        parts.append("\(seconds) second\(seconds == 1 ? "" : "s")")
        return parts.joined(separator: ", ")
    }

    // MARK: - Actions

    private func startRecording() {
        do {
            _ = try audioService.startRecording()
        } catch {
            print("[RecordingView] Failed to start recording: \(error)")
            onCancel()
        }
    }

    private func stopAndFinish() {
        guard let audioURL = audioService.stopRecording() else {
            onStop(nil)
            return
        }

        var meeting = Meeting(
            title: "Meeting \(formattedDateForTitle)",
            date: Date(),
            duration: audioService.duration,
            audioFilePath: audioURL.path,
            clientName: detectedClient,
            status: .processing,
            template: selectedTemplate,
            userNotes: notes.isEmpty ? nil : notes
        )

        meetingService.currentRecording = meeting
        onStop(meeting)
    }

    private func discardRecording() {
        _ = audioService.stopRecording()
        onCancel()
    }

    private func updateWaveform(level: CGFloat) {
        // Shift levels left and add new level at the center, mirrored
        var newLevels = waveformLevels
        let mid = barCount / 2

        // Shift outer bars
        for i in 0..<mid {
            newLevels[i] = newLevels[i + 1]
        }
        for i in stride(from: barCount - 1, to: mid, by: -1) {
            newLevels[i] = newLevels[i - 1]
        }

        // Set center with some randomness for visual interest
        let randomVariation = CGFloat.random(in: -0.15...0.15)
        let centerLevel = min(1.0, max(0.05, level + randomVariation))
        newLevels[mid] = centerLevel
        newLevels[mid - 1] = min(1.0, max(0.05, level + CGFloat.random(in: -0.1...0.1)))
        newLevels[mid + 1] = min(1.0, max(0.05, level + CGFloat.random(in: -0.1...0.1)))

        waveformLevels = newLevels
    }

    private var formattedDateForTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: Date())
    }
}

// MARK: - Preview

#Preview {
    RecordingView(
        onStop: { _ in },
        onCancel: {}
    )
    .environmentObject(MeetingService.shared)
}
