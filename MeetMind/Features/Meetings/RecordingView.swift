import SwiftUI
import AVFoundation

struct RecordingView: View {
    @StateObject private var audioService = AudioRecordingService.shared
    @StateObject private var liveTranscription = LiveTranscriptionService.shared
    @EnvironmentObject var meetingService: MeetingService

    @State private var notes: String = ""
    @State private var detectedClient: String?
    @State private var waveformLevels: [CGFloat] = Array(repeating: 0.05, count: 30)
    @State private var pulseScale: CGFloat = 1.0
    @State private var showCancelConfirm = false
    @State private var showDurationWarning = false
    @State private var selectedTemplate: MeetingTemplate = .general
    @State private var notepadContent: String = ""
    @State private var meetingTitle: String = ""

    @FocusState private var isTitleFocused: Bool
    @FocusState private var isNotesFocused: Bool

    let onStop: (Meeting?) -> Void
    let onCancel: () -> Void
    let onMinimize: () -> Void

    private let barCount = 20

    var body: some View {
        ZStack {
            MMColors.background.ignoresSafeArea()

            GeometryReader { geo in
                VStack(spacing: 0) {
                    // Top bar — minimal
                    topBar
                        .padding(.top, 8)

                    // Full-page notepad — takes 75% of remaining space
                    notepadArea
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .frame(maxHeight: geo.size.height * 0.75)

                    Spacer(minLength: 0)

                    // Live transcript — pinned above controls
                    if liveTranscription.isTranscribing && !liveTranscription.liveText.isEmpty {
                        liveTranscriptPeek
                            .padding(.horizontal, 20)
                            .padding(.bottom, 6)
                    }

                    // Meeting type pills
                    meetingTypePills
                        .padding(.horizontal, 16)
                        .padding(.bottom, 6)

                    // Bottom recording bar — compact
                    recordingBar
                }
            }
        }
        .onAppear {
            startRecording()
            meetingTitle = defaultTitle
        }
        .onTapGesture {
            isTitleFocused = false
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

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                showCancelConfirm = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(MMColors.textTertiary)
                    .frame(width: 36, height: 36)
                    .background(MMColors.cardBg)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(MMColors.border, lineWidth: 1)
                    )
            }
            .padding(.leading, 16)

            Spacer()

            // Recording status + timer
            HStack(spacing: 8) {
                Circle()
                    .fill(audioService.isPaused ? MMColors.warning : MMColors.recording)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulseScale)
                    .animation(
                        audioService.isPaused
                            ? .default
                            : .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: pulseScale
                    )
                    .onAppear { pulseScale = 0.6 }

                Text(formattedTime)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(MMColors.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(MMColors.cardBg)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(MMColors.border, lineWidth: 1)
            )

            Spacer()

            Button {
                onMinimize()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(MMColors.textTertiary)
                    .frame(width: 36, height: 36)
                    .background(MMColors.cardBg)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(MMColors.border, lineWidth: 1)
                    )
            }
            .padding(.trailing, 16)
        }
    }

    // MARK: - Full Notepad Area

    private var notepadArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Meeting title
            TextField("Meeting title...", text: $meetingTitle)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(MMColors.textPrimary)
                .focused($isTitleFocused)
                .padding(.bottom, 16)

            // Divider
            Rectangle()
                .fill(MMColors.border)
                .frame(height: 1)
                .padding(.bottom, 12)

            // Notes area — expands to fill all remaining space
            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Start typing your notes...")
                            .font(.system(size: 16))
                            .foregroundColor(MMColors.textTertiary.opacity(0.5))

                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                                .foregroundColor(MMColors.primary.opacity(0.5))
                            Text("AI will enhance your notes with the transcript")
                                .font(.system(size: 13))
                                .foregroundColor(MMColors.textTertiary.opacity(0.4))
                        }
                    }
                    .padding(.top, 8)
                    .allowsHitTesting(false)
                }

                TextEditor(text: $notes)
                    .font(.system(size: 16))
                    .foregroundColor(MMColors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .tint(MMColors.primary)
                    .focused($isNotesFocused)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Live Transcript Peek

    private var liveTranscriptPeek: some View {
        HStack(spacing: 10) {
            // Pulsing waveform icon
            Image(systemName: "waveform")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MMColors.primary)
                .symbolEffect(.pulse, isActive: !audioService.isPaused)

            Text(String(liveTranscription.liveText.suffix(120)))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(MMColors.textSecondary)
                .lineLimit(2)
                .truncationMode(.head)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MMColors.primaryLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(MMColors.primary.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Meeting Type Pills

    private var meetingTypePills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MeetingTemplate.allCases, id: \.self) { template in
                    let isSelected = selectedTemplate == template
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTemplate = template
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: template.icon)
                                .font(.system(size: 11, weight: .medium))
                            Text(template.rawValue)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(isSelected ? .white : MMColors.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            isSelected
                                ? MMColors.primary
                                : MMColors.cardBg
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? MMColors.primary : MMColors.border, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Bottom Recording Bar

    private var recordingBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(MMColors.border)
                .frame(height: 1)

            VStack(spacing: 8) {
                // Centered waveform — compact
                compactWaveform
                    .frame(height: 28)
                    .padding(.horizontal, 24)
                    .padding(.top, 10)

                // Controls row
                HStack(spacing: 20) {
                    // Duration warning (left)
                    if audioService.duration >= 7200 {
                        let remaining = max(0, 10800 - audioService.duration)
                        let remainingMinutes = Int(remaining) / 60
                        Text("\(remainingMinutes)m left")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(remaining <= 900 ? MMColors.recording : MMColors.warning)
                            .frame(width: 50)
                    } else {
                        Color.clear.frame(width: 50)
                    }

                    Spacer()

                    // Pause / Resume
                    Button {
                        if audioService.isPaused {
                            audioService.resumeRecording()
                        } else {
                            audioService.pauseRecording()
                        }
                    } label: {
                        Image(systemName: audioService.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(MMColors.textPrimary)
                            .frame(width: 46, height: 46)
                            .background(MMColors.cardBg)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(MMColors.border, lineWidth: 1)
                            )
                    }

                    // Stop
                    Button {
                        stopAndFinish()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(MMColors.recording)
                                .frame(width: 46, height: 46)
                                .shadow(color: MMColors.recording.opacity(0.4), radius: 8, x: 0, y: 2)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white)
                                .frame(width: 18, height: 18)
                        }
                    }

                    Spacer()

                    Color.clear.frame(width: 50)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
            .background(MMColors.backgroundElevated)
        }
    }

    // MARK: - Compact Waveform

    private var compactWaveform: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(MMColors.primary.opacity(audioService.isPaused ? 0.25 : 0.65))
                    .frame(maxWidth: .infinity, minHeight: 4, maxHeight: max(4, waveformLevels[index] * 28))
                    .animation(.easeOut(duration: 0.1), value: waveformLevels[index])
            }
        }
    }

    // MARK: - Formatted Time

    private var formattedTime: String {
        let totalSeconds = Int(audioService.duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var defaultTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: Date())
    }

    // MARK: - Actions

    private func startRecording() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            doStartRecording()
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        doStartRecording()
                    } else {
                        onCancel()
                    }
                }
            }
        case .denied:
            onCancel()
        @unknown default:
            onCancel()
        }
    }

    private func doStartRecording() {
        do {
            _ = try audioService.startRecording()
            Task {
                let authorized = await liveTranscription.requestAuthorization()
                if authorized {
                    liveTranscription.startLiveTranscription()
                }
            }
        } catch {
            print("[RecordingView] Failed to start recording: \(error)")
            onCancel()
        }
    }

    private func stopAndFinish() {
        liveTranscription.stopLiveTranscription()
        let recordedDuration = audioService.duration

        guard let audioURL = audioService.stopRecording() else {
            onStop(nil)
            return
        }

        let meeting = Meeting(
            title: meetingTitle.isEmpty ? "Meeting \(defaultTitle)" : meetingTitle,
            date: Date(),
            duration: recordedDuration,
            audioFilePath: audioURL.path,
            clientName: detectedClient,
            status: .processing,
            template: selectedTemplate,
            userNotes: notes.isEmpty ? nil : notes,
            notepadContent: notepadContent.isEmpty ? nil : notepadContent
        )

        meetingService.currentRecording = meeting
        onStop(meeting)
    }

    private func discardRecording() {
        liveTranscription.stopLiveTranscription()
        _ = audioService.stopRecording()
        onCancel()
    }

    private func updateWaveform(level: CGFloat) {
        var newLevels = waveformLevels
        let mid = barCount / 2

        for i in 0..<mid {
            newLevels[i] = newLevels[i + 1]
        }
        for i in stride(from: barCount - 1, to: mid, by: -1) {
            newLevels[i] = newLevels[i - 1]
        }

        let randomVariation = CGFloat.random(in: -0.15...0.15)
        let centerLevel = min(1.0, max(0.05, level + randomVariation))
        newLevels[mid] = centerLevel
        if mid > 0 {
            newLevels[mid - 1] = min(1.0, max(0.05, level + CGFloat.random(in: -0.1...0.1)))
        }
        if mid + 1 < barCount {
            newLevels[mid + 1] = min(1.0, max(0.05, level + CGFloat.random(in: -0.1...0.1)))
        }

        waveformLevels = newLevels
    }
}

// MARK: - Preview

#Preview {
    RecordingView(
        onStop: { _ in },
        onCancel: {},
        onMinimize: {}
    )
    .environmentObject(MeetingService.shared)
}
