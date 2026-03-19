import SwiftUI
import AVFoundation

// MARK: - Audio Player Manager

@MainActor
class AudioPlayerManager: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isReady = false

    private var player: AVAudioPlayer?
    private var timer: Timer?

    func loadAudio(from url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            duration = player?.duration ?? 0
            isReady = duration > 0
        } catch {
            print("[AudioPlayerManager] Failed to load audio: \(error)")
            isReady = false
        }
    }

    func play() {
        guard let player else { return }
        player.play()
        isPlaying = true
        startTimer()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
    }

    func cleanup() {
        pause()
        player?.stop()
        player = nil
        stopTimer()
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let player = self.player else { return }
                self.currentTime = player.currentTime
                if !player.isPlaying {
                    self.isPlaying = false
                    self.stopTimer()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Audio Player View

struct AudioPlayerView: View {
    let audioURL: URL
    var onSeekToTimestamp: ((TimeInterval) -> Void)?

    @StateObject private var playerManager = AudioPlayerManager()

    var body: some View {
        HStack(spacing: 14) {
            // Play / Pause button
            Button {
                playerManager.togglePlayPause()
            } label: {
                Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(MMColors.primary)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(playerManager.isPlaying ? "Pause" : "Play")
            .accessibilityHint("Double-tap to \(playerManager.isPlaying ? "pause" : "play") the recording")

            // Seek slider
            VStack(spacing: 2) {
                Slider(
                    value: Binding(
                        get: { playerManager.currentTime },
                        set: { playerManager.seek(to: $0) }
                    ),
                    in: 0...max(playerManager.duration, 1)
                )
                .tint(MMColors.primary)
                .accessibilityLabel("Playback position")
                .accessibilityValue(formatTime(playerManager.currentTime))

                // Time labels
                HStack {
                    Text(formatTime(playerManager.currentTime))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(MMColors.textSecondary)

                    Spacer()

                    Text("-\(formatTime(max(0, playerManager.duration - playerManager.currentTime)))")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(MMColors.textTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(
            MMColors.cardBg
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: -2)
        )
        .onAppear {
            playerManager.loadAudio(from: audioURL)
        }
        .onDisappear {
            playerManager.cleanup()
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        AudioPlayerView(
            audioURL: URL(fileURLWithPath: "/dev/null")
        )
    }
}
