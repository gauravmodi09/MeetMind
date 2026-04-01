#if os(macOS)
import SwiftUI

enum AudioSource: String, CaseIterable {
    case system = "System Audio"
    case microphone = "Microphone"

    var icon: String {
        switch self {
        case .system: return "display"
        case .microphone: return "mic.fill"
        }
    }
}

struct MacRecordingView: View {
    @EnvironmentObject var meetingService: MeetingService
    @StateObject private var systemCapture = SystemAudioCapture()
    @ObservedObject var appDetector: MeetingAppDetector
    @Binding var isRecording: Bool

    @State private var audioSource: AudioSource = .system
    @State private var duration: TimeInterval = 0
    @State private var meetingTitle = "New Meeting"
    @State private var selectedTemplate: MeetingTemplate = .general
    @State private var timer: Timer?
    @State private var audioFileURL: URL?
    @State private var isEditingTitle = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Recording circle
            ZStack {
                // Outer pulse
                Circle()
                    .fill(MMColors.recording.opacity(0.06))
                    .frame(width: 140, height: 140)
                    .scaleEffect(1.0)

                // Middle ring
                Circle()
                    .stroke(MMColors.recording.opacity(0.15), lineWidth: 2)
                    .frame(width: 100, height: 100)

                // Stop button
                Button {
                    stopRecording()
                } label: {
                    ZStack {
                        Circle()
                            .fill(MMColors.recording)
                            .frame(width: 72, height: 72)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.white)
                            .frame(width: 22, height: 22)
                    }
                }
                .buttonStyle(.plain)
            }

            // Timer
            Text(formatTime(duration))
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundColor(MMColors.textPrimary)
                .padding(.top, 20)

            // Status
            HStack(spacing: 8) {
                Circle()
                    .fill(MMColors.recording)
                    .frame(width: 8, height: 8)

                if isEditingTitle {
                    TextField("Meeting title", text: $meetingTitle)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 200)
                        .onSubmit { isEditingTitle = false }
                } else {
                    Text(meetingTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MMColors.textPrimary)
                        .onTapGesture { isEditingTitle = true }
                }
            }
            .padding(.top, 8)

            // Template selector
            HStack(spacing: 6) {
                ForEach(MeetingTemplate.allCases, id: \.self) { template in
                    Button {
                        selectedTemplate = template
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: template.icon)
                                .font(.system(size: 10))
                            Text(template.rawValue)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(selectedTemplate == template ? .white : MMColors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(selectedTemplate == template ? MMColors.primary : MMColors.background)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7)
                                        .stroke(selectedTemplate == template ? Color.clear : MMColors.border)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 16)

            // Audio source
            VStack(spacing: 10) {
                Text("AUDIO SOURCE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(MMColors.textTertiary)
                    .tracking(0.8)

                HStack(spacing: 8) {
                    ForEach(AudioSource.allCases, id: \.self) { source in
                        Button {
                            // Can't switch during recording
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: source.icon)
                                    .font(.system(size: 12))
                                Text(source.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(audioSource == source ? .white : MMColors.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(audioSource == source ? MMColors.primary : MMColors.backgroundElevated)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(audioSource == source ? Color.clear : MMColors.border)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let app = appDetector.activeMeetingApp {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(MMColors.success)
                        Text("Capturing: \(app.displayName)")
                            .font(.system(size: 11))
                            .foregroundColor(MMColors.textTertiary)
                    }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(MMColors.background)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(MMColors.border))
            )
            .padding(.top, 24)

            // Waveform
            HStack(spacing: 2) {
                ForEach(0..<20, id: \.self) { i in
                    let level = audioSource == .system ? systemCapture.audioLevel : AudioRecordingService.shared.audioLevel
                    let height = max(3, CGFloat(level) * 36 + CGFloat.random(in: 0...6))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(MMColors.primary.opacity(0.6))
                        .frame(width: 3, height: height)
                        .animation(.easeInOut(duration: 0.15), value: level)
                }
            }
            .frame(height: 40)
            .padding(.top, 16)

            // Controls
            HStack(spacing: 14) {
                Button {
                    stopRecording()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 10))
                        Text("Stop & Process")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(MMColors.recording)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(MMColors.backgroundElevated)
        .onAppear {
            startRecording()
        }
    }

    // MARK: - Recording Control

    private func startRecording() {
        if appDetector.isInMeeting {
            audioSource = .system
        } else {
            audioSource = .microphone
        }

        Task {
            do {
                if audioSource == .system {
                    try await systemCapture.startCapture()
                } else {
                    audioFileURL = try AudioRecordingService.shared.startRecording()
                }
                startTimer()
            } catch {
                print("[MacRecording] Failed to start: \(error)")
                isRecording = false
            }
        }
    }

    private func stopRecording() {
        stopTimer()

        Task {
            var fileURL: URL?
            if audioSource == .system {
                fileURL = await systemCapture.stopCapture()
            } else {
                fileURL = AudioRecordingService.shared.stopRecording()
            }

            isRecording = false

            if let url = fileURL {
                await meetingService.processRecordedAudio(url: url, title: meetingTitle)
            }
        }
    }

    private func startTimer() {
        duration = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            duration += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 { return String(format: "%02d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}
#endif
