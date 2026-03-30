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
    @State private var timer: Timer?
    @State private var audioFileURL: URL?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Stop button
            Button {
                stopRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 56, height: 56)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                }
            }
            .buttonStyle(.plain)

            // Timer
            Text(formatTime(duration))
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.180))

            // Status
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text("Recording — \(meetingTitle)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.red)
            }

            // Audio source selector
            VStack(spacing: 8) {
                Text("AUDIO SOURCE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)

                HStack(spacing: 8) {
                    ForEach(AudioSource.allCases, id: \.self) { source in
                        Button {
                            // Can't switch during recording
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: source.icon)
                                    .font(.system(size: 12))
                                Text(source.rawValue)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(audioSource == source ? .white : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(audioSource == source ? MMColors.primary : Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(audioSource == source ? Color.clear : Color(white: 0.9))
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let app = appDetector.activeMeetingApp {
                    Text("Capturing: \(app.displayName)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(red: 0.973, green: 0.973, blue: 0.980)))

            // Waveform
            HStack(spacing: 2) {
                ForEach(0..<15, id: \.self) { i in
                    let level = audioSource == .system ? systemCapture.audioLevel : AudioRecordingService.shared.audioLevel
                    let height = max(4, CGFloat(level) * 40 + CGFloat.random(in: 0...8))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(MMColors.primary)
                        .frame(width: 3, height: height)
                        .animation(.easeInOut(duration: 0.15), value: level)
                }
            }
            .frame(height: 40)

            // Controls
            HStack(spacing: 12) {
                Button("⏸ Pause") {
                    // Future: pause support
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.94, green: 0.94, blue: 0.96)))
                .buttonStyle(.plain)

                Button("⏹ Stop & Process") {
                    stopRecording()
                }
                .foregroundColor(.white)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.red))
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
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
