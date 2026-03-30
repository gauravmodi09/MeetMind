#if os(macOS)
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var meetingService: MeetingService
    @StateObject private var systemCapture = SystemAudioCapture()
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var audioFileURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("MeetMind")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(isRecording ? "Recording..." : "Ready to record")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                LinearGradient(colors: [MMColors.primary, Color(red: 0.659, green: 0.333, blue: 0.969)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )

            if isRecording {
                // Recording state
                VStack(spacing: 10) {
                    Text(formatTime(recordingDuration))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                    Button {
                        stopMenuBarRecording()
                    } label: {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("Stop Recording")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.large)
                }
                .padding(12)
            } else {
                // Quick actions
                HStack(spacing: 8) {
                    Button {
                        startMicRecording()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "mic.fill").font(.system(size: 11))
                            Text("Record Mic").font(.system(size: 11, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(MMColors.primary)
                    .controlSize(.regular)

                    Button {
                        startSystemRecording()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "display").font(.system(size: 11))
                            Text("System").font(.system(size: 11, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.102, green: 0.102, blue: 0.180))
                    .controlSize(.regular)
                }
                .padding(12)
            }

            Divider()

            // Recent meetings
            if !meetingService.meetings.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("RECENT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                        .padding(.horizontal, 14)
                        .padding(.top, 10)
                        .padding(.bottom, 6)

                    ForEach(meetingService.meetings.prefix(3)) { meeting in
                        HStack {
                            Text(meeting.title)
                                .font(.system(size: 12))
                                .lineLimit(1)
                            Spacer()
                            Text(meeting.date, style: .relative)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                    }
                }
                .padding(.bottom, 6)
            }

            Divider()

            // Footer
            HStack {
                Button("Open MeetMind") {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { !($0 is NSPanel) }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(MMColors.primary)
                .buttonStyle(.plain)

                Spacer()

                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .frame(width: 280)
    }

    // MARK: - Recording

    private func startMicRecording() {
        do {
            audioFileURL = try AudioRecordingService.shared.startRecording()
            isRecording = true
            startTimer()
        } catch {
            print("[MenuBar] Mic recording failed: \(error)")
        }
    }

    private func startSystemRecording() {
        Task {
            do {
                try await systemCapture.startCapture()
                isRecording = true
                startTimer()
            } catch {
                print("[MenuBar] System capture failed: \(error)")
            }
        }
    }

    private func stopMenuBarRecording() {
        stopTimer()
        isRecording = false

        Task {
            var fileURL: URL?
            if systemCapture.isCapturing {
                fileURL = await systemCapture.stopCapture()
            } else {
                fileURL = AudioRecordingService.shared.stopRecording()
            }

            if let url = fileURL {
                await meetingService.processRecordedAudio(url: url, title: "Meeting \(Date().formatted(date: .abbreviated, time: .shortened))")
            }
        }
    }

    private func startTimer() {
        recordingDuration = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            recordingDuration += 1
        }
    }

    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
#endif
