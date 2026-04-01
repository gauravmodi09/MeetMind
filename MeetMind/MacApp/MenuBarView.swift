#if os(macOS)
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var meetingService: MeetingService
    @StateObject private var systemCapture = SystemAudioCapture()
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var audioFileURL: URL?
    @State private var hoveredMeetingId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [MMColors.primary, MMColors.primary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("MeetMind")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(MMColors.textPrimary)
                    Text(isRecording ? "Recording..." : "Ready to record")
                        .font(.system(size: 10))
                        .foregroundColor(isRecording ? MMColors.recording : MMColors.textTertiary)
                }
                Spacer()
            }
            .padding(14)

            Divider()

            if isRecording {
                // Recording state
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(MMColors.recording)
                            .frame(width: 8, height: 8)
                        Text(formatTime(recordingDuration))
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(MMColors.textPrimary)
                    }

                    // Waveform
                    HStack(spacing: 2) {
                        ForEach(0..<12, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(MMColors.recording.opacity(0.6))
                                .frame(width: 3, height: CGFloat.random(in: 4...18))
                        }
                    }
                    .frame(height: 20)

                    Button {
                        stopMenuBarRecording()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 10))
                            Text("Stop & Process")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(MMColors.recording)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
            } else {
                // Quick actions
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        recordButton(
                            title: "Microphone",
                            icon: "mic.fill",
                            color: MMColors.primary
                        ) {
                            startMicRecording()
                        }

                        recordButton(
                            title: "System Audio",
                            icon: "display",
                            color: MMColors.info
                        ) {
                            startSystemRecording()
                        }
                    }

                    // Quick stats
                    HStack(spacing: 0) {
                        menuStatItem(value: "\(meetingService.meetings.count)", label: "Meetings")
                        Spacer()
                        menuStatItem(value: "\(pendingActionCount)", label: "Pending")
                        Spacer()
                        menuStatItem(value: "\(todayMeetingCount)", label: "Today")
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(MMColors.background)
                    )
                }
                .padding(14)
            }

            Divider()

            // Recent meetings
            if !meetingService.meetings.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("RECENT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(MMColors.textTertiary)
                        .tracking(0.8)
                        .padding(.horizontal, 14)
                        .padding(.top, 10)
                        .padding(.bottom, 6)

                    ForEach(meetingService.meetings.sorted(by: { $0.date > $1.date }).prefix(4)) { meeting in
                        HStack(spacing: 8) {
                            Image(systemName: meeting.template.icon)
                                .font(.system(size: 10))
                                .foregroundColor(MMColors.primary)
                                .frame(width: 16)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(meeting.title)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(MMColors.textPrimary)
                                    .lineLimit(1)
                                HStack(spacing: 4) {
                                    Text(meeting.date, style: .relative)
                                    if let client = meeting.clientName {
                                        Text("·")
                                        Text(client)
                                    }
                                }
                                .font(.system(size: 9))
                                .foregroundColor(MMColors.textTertiary)
                            }

                            Spacer()

                            Circle()
                                .fill(meeting.status == .complete ? MMColors.success : MMColors.warning)
                                .frame(width: 6, height: 6)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(hoveredMeetingId == meeting.id ? MMColors.background : Color.clear)
                        )
                        .onHover { h in hoveredMeetingId = h ? meeting.id : nil }
                    }
                }
                .padding(.bottom, 6)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "waveform.circle")
                        .font(.system(size: 20))
                        .foregroundColor(MMColors.textTertiary.opacity(0.5))
                    Text("No meetings yet")
                        .font(.system(size: 11))
                        .foregroundColor(MMColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

            Divider()

            // Footer
            HStack {
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { !($0 is NSPanel) }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "macwindow")
                            .font(.system(size: 10))
                        Text("Open MeetMind")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(MMColors.primary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    NSApp.terminate(nil)
                } label: {
                    Text("Quit")
                        .font(.system(size: 11))
                        .foregroundColor(MMColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(width: 300)
    }

    // MARK: - Components

    private func recordButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(MMColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(color.opacity(0.15))
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func menuStatItem(value: String, label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(MMColors.textPrimary)
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(MMColors.textTertiary)
        }
    }

    // MARK: - Computed

    private var pendingActionCount: Int {
        meetingService.meetings.reduce(0) { $0 + $1.briefActionItems.filter { !$0.isCompleted }.count }
    }

    private var todayMeetingCount: Int {
        meetingService.meetings.filter { Calendar.current.isDateInToday($0.date) }.count
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
