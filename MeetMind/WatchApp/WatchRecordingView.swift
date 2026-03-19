import SwiftUI

// MARK: - Watch-Style Recording View
// Designed for Apple Watch form factor. Currently runs as an iOS view for demo/preview.
// When a watchOS target is added, wrap contents in #if os(watchOS) and move to that target.

// Note: Double-tap gesture requires watchOS 10+ on Series 9/Ultra 2
// When running on compatible hardware, register for:
// WKApplication.shared().registerForRemoteNotifications()
// and handle the double-tap action via WKExtensionDelegate's
// didReceiveRemoteNotification handler.

/// Watch-style recording view optimized for small screens and large tap targets.
/// Will be moved to a dedicated watchOS target in a future milestone.
struct WatchRecordingView: View {
    @StateObject private var recorder = AudioRecordingService.shared

    @State private var isRecording = false
    @State private var elapsedSeconds: Int = 0
    @State private var waveformLevels: [CGFloat] = [0.3, 0.5, 0.8, 0.4, 0.6]
    @State private var showLowBatteryWarning = false

    // Simulated battery level for iOS preview (watchOS would use WKInterfaceDevice)
    @State private var simulatedBatteryLevel: Float = 0.45

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let waveformTimer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    // MARK: - Watch Background Color

    private let watchBackground = Color(hex: "1A1A2E")

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // Low battery warning banner
            if showLowBatteryWarning {
                lowBatteryBanner
            }

            // Header
            Text("MeetMind")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MMColors.primary)

            if isRecording {
                recordingStateView
            } else {
                idleStateView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(watchBackground)
        .onReceive(timer) { _ in
            guard isRecording else { return }
            elapsedSeconds += 1
            checkBatteryLevel()
        }
        .onReceive(waveformTimer) { _ in
            guard isRecording else { return }
            updateWaveform()
        }
        .onAppear {
            checkBatteryLevel()
        }
    }

    // MARK: - Idle State (Record Button)

    private var idleStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Button {
                startRecording()
            } label: {
                Circle()
                    .fill(MMColors.recording)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "mic.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 28))
                    )
                    .shadow(color: MMColors.recording.opacity(0.4), radius: 8, y: 4)
            }
            .buttonStyle(.plain)

            Text("Tap to Record")
                .font(.system(size: 13))
                .foregroundColor(.gray)

            Spacer()
        }
    }

    // MARK: - Recording State

    private var recordingStateView: some View {
        VStack(spacing: 14) {
            Spacer()

            // Elapsed timer (HH:MM:SS monospace)
            Text(formattedTime)
                .font(.system(size: 28, weight: .light, design: .monospaced))
                .foregroundColor(.white)

            // Mini waveform (5 bars)
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(MMColors.recording)
                        .frame(width: 4, height: waveformLevels[index] * 24)
                        .animation(.easeInOut(duration: 0.15), value: waveformLevels[index])
                }
            }
            .frame(height: 24)

            // Stop button
            Button {
                stopRecording()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 12))
                    Text("Stop")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: 120, height: 44)
                .background(MMColors.recording)
                .cornerRadius(22)
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    // MARK: - Low Battery Banner (Task MM-049)

    private var lowBatteryBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "battery.25")
                .font(.system(size: 11))
            Text("Low battery \u{2014} consider continuing on iPhone")
                .font(.system(size: 10, weight: .medium))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(MMColors.warning.opacity(0.85))
        .cornerRadius(8)
        .padding(.horizontal, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Formatted Time

    private var formattedTime: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Actions

    private func startRecording() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isRecording = true
        }
        elapsedSeconds = 0
        // In production, this would call:
        // try recorder.startRecording()
    }

    private func stopRecording() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isRecording = false
        }
        // In production, this would call:
        // recorder.stopRecording()
    }

    private func updateWaveform() {
        // Simulate waveform from audio levels
        // On real watchOS, this would read from recorder.audioLevel
        for i in 0..<5 {
            waveformLevels[i] = CGFloat.random(in: 0.15...1.0)
        }
    }

    // MARK: - Battery Check (MM-049)

    private func checkBatteryLevel() {
        // On watchOS, use: WKInterfaceDevice.current().batteryLevel
        // On iOS preview, we use the simulated value
        let batteryLevel = simulatedBatteryLevel

        let isLow = batteryLevel < 0.10 && batteryLevel >= 0
        if isLow != showLowBatteryWarning {
            withAnimation(.easeInOut(duration: 0.3)) {
                showLowBatteryWarning = isLow
            }
        }
        // Note: We intentionally do NOT auto-stop recording on low battery.
        // The user decides when to stop.
    }
}

// MARK: - Watch Frame Preview Wrapper

/// Wraps a view in a simulated Apple Watch bezel for previews.
private struct WatchPreviewFrame<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(width: 198, height: 242) // ~45mm Apple Watch
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 2)
            )
    }
}

// MARK: - Previews

#Preview("Idle") {
    WatchPreviewFrame {
        WatchRecordingView()
    }
    .padding()
    .background(Color.black)
}

#Preview("Recording") {
    WatchPreviewFrame {
        WatchRecordingView()
    }
    .padding()
    .background(Color.black)
}
