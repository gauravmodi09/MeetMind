import AVFoundation
import Combine

@MainActor
class AudioRecordingService: ObservableObject {
    static let shared = AudioRecordingService()

    // MARK: - Published State

    @Published var isRecording = false
    @Published var isPaused = false
    @Published var duration: TimeInterval = 0
    @Published var audioLevel: Float = 0 // 0-1 normalized for waveform

    // MARK: - Private

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var levelTimer: Timer?
    private var recordingStartDate: Date?
    private var accumulatedDuration: TimeInterval = 0
    private var currentFileURL: URL?

    private let maxDuration: TimeInterval = 3 * 60 * 60       // 3 hours
    private let warningDuration: TimeInterval = 2 * 60 * 60 + 45 * 60 // 2h 45m
    private var warningPosted = false

    private let groqFileSizeLimit: Int = 24 * 1024 * 1024 // 24 MB threshold (Groq limit 25 MB)
    private let minimumDiskSpaceBytes: Int64 = 100 * 1024 * 1024 // 100 MB minimum free space

    // MARK: - Notifications

    static let maxDurationWarningNotification = Notification.Name("AudioRecordingMaxDurationWarning")
    static let maxDurationReachedNotification = Notification.Name("AudioRecordingMaxDurationReached")
    static let lowDiskSpaceNotification = Notification.Name("AudioRecordingLowDiskSpace")

    // MARK: - Init

    private init() {
        setupInterruptionHandling()
    }

    // MARK: - Recording Controls

    func startRecording() throws -> URL {
        // Check available disk space before starting
        try checkDiskSpace()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)

        let fileURL = makeRecordingURL()
        currentFileURL = fileURL

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.record()

        audioRecorder = recorder
        isRecording = true
        isPaused = false
        duration = 0
        accumulatedDuration = 0
        recordingStartDate = Date()
        warningPosted = false

        startTimers()

        return fileURL
    }

    func pauseRecording() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.pause()
        isPaused = true

        // Accumulate elapsed time
        if let start = recordingStartDate {
            accumulatedDuration += Date().timeIntervalSince(start)
        }
        recordingStartDate = nil

        stopTimers()
    }

    func resumeRecording() {
        guard let recorder = audioRecorder, isPaused else { return }
        recorder.record()
        isPaused = false
        recordingStartDate = Date()

        startTimers()
    }

    func stopRecording() -> URL? {
        guard let recorder = audioRecorder else { return nil }

        // Final duration calculation
        if let start = recordingStartDate {
            accumulatedDuration += Date().timeIntervalSince(start)
        }
        duration = accumulatedDuration

        recorder.stop()
        stopTimers()

        isRecording = false
        isPaused = false
        recordingStartDate = nil
        audioLevel = 0

        let url = currentFileURL
        audioRecorder = nil
        currentFileURL = nil

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        return url
    }

    // MARK: - Compression

    /// Compresses audio if the file exceeds the Groq upload limit (24 MB).
    /// Returns the original URL if no compression is needed.
    func compressAudioIfNeeded(url: URL) async throws -> URL {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = (attributes[.size] as? Int) ?? 0

        guard fileSize > groqFileSizeLimit else { return url }

        let asset = AVURLAsset(url: url)
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw RecordingError.compressionFailed
        }

        let compressedURL = url.deletingLastPathComponent()
            .appendingPathComponent("compressed_\(url.lastPathComponent)")

        // Remove any previous compressed file at this path
        try? FileManager.default.removeItem(at: compressedURL)

        session.outputURL = compressedURL
        session.outputFileType = .m4a

        await session.export()

        switch session.status {
        case .completed:
            return compressedURL
        case .failed:
            throw session.error ?? RecordingError.compressionFailed
        case .cancelled:
            throw RecordingError.compressionCancelled
        default:
            throw RecordingError.compressionFailed
        }
    }

    // MARK: - Timers

    private func startTimers() {
        // Duration timer: every 1s
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateDuration()
            }
        }

        // Level timer: every 0.1s
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateLevel()
            }
        }
    }

    private func stopTimers() {
        timer?.invalidate()
        timer = nil
        levelTimer?.invalidate()
        levelTimer = nil
    }

    private func updateDuration() {
        guard let start = recordingStartDate else { return }
        duration = accumulatedDuration + Date().timeIntervalSince(start)

        // 2h 45m warning
        if !warningPosted && duration >= warningDuration {
            warningPosted = true
            NotificationCenter.default.post(name: Self.maxDurationWarningNotification, object: nil)
        }

        // 3h hard stop
        if duration >= maxDuration {
            NotificationCenter.default.post(name: Self.maxDurationReachedNotification, object: nil)
            _ = stopRecording()
        }
    }

    private func updateLevel() {
        guard let recorder = audioRecorder, recorder.isRecording else {
            audioLevel = 0
            return
        }

        recorder.updateMeters()
        let decibels = recorder.averagePower(forChannel: 0) // -160...0
        // Normalize to 0-1 range (treat -60 dB as silence floor)
        let normalized = max(0, min(1, (decibels + 60) / 60))
        audioLevel = normalized
    }

    // MARK: - Interruption Handling

    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                self?.handleInterruption(notification)
            }
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            if isRecording && !isPaused {
                pauseRecording()
            }
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) && isPaused {
                    resumeRecording()
                }
            }
        @unknown default:
            break
        }
    }

    // MARK: - Disk Space

    /// Checks available disk space and throws if below the minimum threshold.
    private func checkDiskSpace() throws {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let values = try documentsURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let availableBytes = values.volumeAvailableCapacityForImportantUsage {
                if availableBytes < minimumDiskSpaceBytes {
                    NotificationCenter.default.post(name: Self.lowDiskSpaceNotification, object: nil)
                    throw RecordingError.insufficientDiskSpace
                }
            }
        } catch let error as RecordingError {
            throw error
        } catch {
            // If we can't determine disk space, log and continue
            print("[AudioRecordingService] Could not determine available disk space: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func makeRecordingURL() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let filename = "meeting_\(timestamp).m4a"

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(filename)
    }
}

// MARK: - Errors

enum RecordingError: LocalizedError {
    case compressionFailed
    case compressionCancelled
    case insufficientDiskSpace

    var errorDescription: String? {
        switch self {
        case .compressionFailed:      return "Audio compression failed."
        case .compressionCancelled:   return "Audio compression was cancelled."
        case .insufficientDiskSpace:  return "Not enough disk space to record. Please free up at least 100 MB and try again."
        }
    }
}
