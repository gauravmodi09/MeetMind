import SwiftUI
import Combine
import AVFoundation
import WatchConnectivity
import WatchKit

// MARK: - MeetMind Watch App
// Standalone recorder for in-person meetings: captures audio on the watch and
// transfers it to the iPhone, which transcribes and writes the notes. Tapping
// the face complication opens this app via `meetmind://record`, which
// auto-starts recording.

@main
struct MeetMindWatchApp: App {
    @StateObject private var recorder = WatchRecorder()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(recorder)
                .onOpenURL { url in
                    // Complication / deep link: meetmind://record
                    if url.host == "record" && !recorder.isRecording {
                        recorder.startRecording()
                    }
                }
        }
    }
}

// MARK: - Watch Audio Recorder

@MainActor
final class WatchRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var duration: TimeInterval = 0
    @Published var transferStatus: String = ""
    @Published var isTransferring = false

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var recordingURL: URL?

    override init() {
        super.init()
        activateConnectivity()
    }

    // MARK: - Recording

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("[WatchRecorder] Audio session error: \(error)")
            transferStatus = "Audio unavailable"
            return
        }

        switch AVAudioApplication.shared.recordPermission {
        case .undetermined:
            AVAudioApplication.requestRecordPermission { granted in
                Task { @MainActor in
                    if granted { self.beginRecording() }
                    else { self.transferStatus = "Mic access denied" }
                }
            }
        case .granted:
            beginRecording()
        case .denied:
            transferStatus = "Mic access denied"
        @unknown default:
            break
        }
    }

    private func beginRecording() {
        let url = makeRecordingURL()
        recordingURL = url

        // 16 kHz mono AAC: small files for fast watch→phone transfer; plenty
        // of fidelity for speech transcription.
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16_000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
            AVEncoderBitRateKey: 32_000
        ]

        do {
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.delegate = self
            recorder.record()
            audioRecorder = recorder
            isRecording = true
            duration = 0
            transferStatus = ""
            startTimer()
            WKInterfaceDevice.current().play(.start)
        } catch {
            print("[WatchRecorder] Failed to start: \(error)")
            transferStatus = "Recording failed"
        }
    }

    func stopRecording() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.stop()
        stopTimer()
        isRecording = false
        WKInterfaceDevice.current().play(.stop)

        if let url = recordingURL {
            transferToPhone(url: url)
        }
    }

    // MARK: - Transfer to iPhone

    private func transferToPhone(url: URL) {
        guard WCSession.default.activationState == .activated else {
            // The file stays on disk; transfer can be retried later.
            transferStatus = "Will send when connected"
            return
        }

        isTransferring = true
        transferStatus = "Sending to iPhone…"

        let metadata: [String: Any] = [
            "type": "audioRecording",
            "fileName": url.lastPathComponent,
            "timestamp": Date().timeIntervalSince1970,
            "duration": duration
        ]
        // transferFile queues and survives disconnects — delivered when the
        // phone is reachable.
        WCSession.default.transferFile(url, metadata: metadata)
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.duration += 1 }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Helpers

    private func makeRecordingURL() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return dir.appendingPathComponent("watch_\(formatter.string(from: Date())).m4a")
    }

    private func activateConnectivity() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
}

// MARK: - AVAudioRecorderDelegate

extension WatchRecorder: @preconcurrency AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            Task { @MainActor in
                self.transferStatus = "Recording failed"
                self.isRecording = false
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchRecorder: @preconcurrency WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("[WatchRecorder] WC activation error: \(error)")
        }
    }

    nonisolated func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        Task { @MainActor in
            self.isTransferring = false
            if let error = error {
                self.transferStatus = "Transfer failed"
                print("[WatchRecorder] Transfer error: \(error)")
            } else {
                self.transferStatus = "Sent to iPhone!"
                WKInterfaceDevice.current().play(.success)
                try? FileManager.default.removeItem(at: fileTransfer.file.fileURL)
                try? await Task.sleep(for: .seconds(3))
                self.transferStatus = ""
            }
        }
    }
}

// MARK: - Watch Home View

struct WatchHomeView: View {
    @EnvironmentObject var recorder: WatchRecorder

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if recorder.isRecording {
                    Text(formatDuration(recorder.duration))
                        .font(.system(size: 30, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                        .monospacedDigit()

                    Button(action: { recorder.stopRecording() }) {
                        Label("Stop", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .tint(.red)
                } else {
                    Button(action: { recorder.startRecording() }) {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle().fill(Color.purple.opacity(0.2)).frame(width: 64, height: 64)
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.purple)
                            }
                            Text("Record Meeting")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .buttonStyle(.plain)
                }

                if recorder.isTransferring {
                    ProgressView().tint(.purple)
                    Text(recorder.transferStatus)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } else if !recorder.transferStatus.isEmpty {
                    Text(recorder.transferStatus)
                        .font(.footnote)
                        .foregroundColor(recorder.transferStatus.contains("Sent") ? .green : .orange)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 8)
        }
        .navigationTitle("MeetMind")
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
