#if os(macOS)
import ScreenCaptureKit
import AVFoundation
import Combine

@MainActor
class SystemAudioCapture: ObservableObject {
    @Published var isCapturing = false
    @Published var audioLevel: Float = 0

    private var stream: SCStream?
    private var audioFile: AVAudioFile?
    private var outputURL: URL?

    // Get available audio-capable content
    func availableContent() async throws -> SCShareableContent {
        try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
    }

    // Start capturing system audio
    func startCapture() async throws {
        let content = try await availableContent()

        // Use the entire display for audio capture
        guard let display = content.displays.first else {
            throw CaptureError.noDisplay
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])

        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.excludesCurrentProcessAudio = true
        config.sampleRate = 16000
        config.channelCount = 1

        // Set up audio file for recording
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "system_audio_\(Date().timeIntervalSince1970).m4a"
        outputURL = tempDir.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        audioFile = try AVAudioFile(forWriting: outputURL!, settings: settings)

        let stream = SCStream(filter: filter, configuration: config, delegate: nil)

        let output = AudioStreamOutput(audioFile: audioFile!) { [weak self] level in
            Task { @MainActor in
                self?.audioLevel = level
            }
        }
        try stream.addStreamOutput(output, type: .audio, sampleBufferQueue: .global(qos: .userInteractive))

        try await stream.startCapture()
        self.stream = stream
        isCapturing = true
    }

    func stopCapture() async -> URL? {
        guard let stream else { return nil }
        try? await stream.stopCapture()
        self.stream = nil
        audioFile = nil
        isCapturing = false
        return outputURL
    }

    enum CaptureError: LocalizedError {
        case noDisplay
        var errorDescription: String? {
            switch self {
            case .noDisplay: return "No display found for audio capture"
            }
        }
    }
}

// SCStreamOutput delegate for audio processing
class AudioStreamOutput: NSObject, SCStreamOutput {
    private let audioFile: AVAudioFile
    private let levelCallback: (Float) -> Void

    init(audioFile: AVAudioFile, levelCallback: @escaping (Float) -> Void) {
        self.audioFile = audioFile
        self.levelCallback = levelCallback
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }
        guard let formatDescription = sampleBuffer.formatDescription,
              let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) else { return }

        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }

        var length = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)

        guard let data = dataPointer else { return }

        // Calculate audio level
        let floatData = UnsafeRawPointer(data).assumingMemoryBound(to: Float.self)
        let frameCount = length / MemoryLayout<Float>.size
        var sum: Float = 0
        for i in 0..<frameCount {
            sum += abs(floatData[i])
        }
        let avgLevel = frameCount > 0 ? sum / Float(frameCount) : 0
        levelCallback(avgLevel)

        // Write to file
        if let pcmBuffer = createPCMBuffer(from: sampleBuffer, asbd: asbd) {
            try? audioFile.write(from: pcmBuffer)
        }
    }

    private func createPCMBuffer(from sampleBuffer: CMSampleBuffer, asbd: UnsafePointer<AudioStreamBasicDescription>) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(streamDescription: asbd) else { return nil }
        let frameCount = CMSampleBufferGetNumSamples(sampleBuffer)
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { return nil }
        pcmBuffer.frameLength = AVAudioFrameCount(frameCount)

        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return nil }
        let status = CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: CMBlockBufferGetDataLength(blockBuffer), destination: pcmBuffer.floatChannelData![0])
        guard status == kCMBlockBufferNoErr else { return nil }

        return pcmBuffer
    }
}
#endif
