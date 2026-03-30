import Speech
import AVFoundation

@MainActor
class VoiceDictationService: ObservableObject {

    enum DictationState: Equatable {
        case idle
        case listening
        case finishing
    }

    @Published var state: DictationState = .idle
    @Published var currentText: String = ""
    @Published var isAuthorized: Bool = false

    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    init() {
        isAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        isAuthorized = status == .authorized
        return isAuthorized
    }

    // MARK: - One-shot Start

    /// Authorize speech + mic, configure audio session, then start dictation.
    func requestAndStart() async {
        guard state == .idle else { return }

        // 1. Speech recognition authorization
        if !isAuthorized {
            _ = await requestAuthorization()
        }
        guard isAuthorized else {
            print("[VoiceDictation] Speech recognition not authorized")
            return
        }

        // 2. Microphone permission
        let micStatus = AVAudioApplication.shared.recordPermission
        if micStatus == .undetermined {
            let granted = await AVAudioApplication.requestRecordPermission()
            guard granted else {
                print("[VoiceDictation] Microphone permission denied")
                return
            }
        } else if micStatus == .denied {
            print("[VoiceDictation] Microphone permission denied")
            return
        }

        startDictation()
    }

    // MARK: - Start Dictation

    func startDictation() {
        guard state == .idle, isAuthorized else { return }

        currentText = ""

        // Configure audio session
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("[VoiceDictation] Failed to configure audio session: \(error)")
            return
        }
        #endif

        startSFSpeechRecognizer()
    }

    // MARK: - Stop Dictation

    func stopDictation() {
        guard state != .idle else { return }
        state = .finishing

        // Stop engine first
        if let engine = audioEngine, engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil

        // End recognition
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        speechRecognizer = nil

        // Deactivate audio session
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif

        state = .idle
    }

    // MARK: - SFSpeechRecognizer (all iOS versions)

    private func startSFSpeechRecognizer() {
        let recognizer = SFSpeechRecognizer(locale: .current)
        guard let recognizer, recognizer.isAvailable else {
            print("[VoiceDictation] SFSpeechRecognizer not available")
            return
        }

        speechRecognizer = recognizer

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request

        // Create a fresh audio engine
        let engine = AVAudioEngine()
        audioEngine = engine

        // Set up audio engine BEFORE starting recognition
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Validate format
        guard recordingFormat.channelCount > 0, recordingFormat.sampleRate > 0 else {
            print("[VoiceDictation] Invalid audio format: ch=\(recordingFormat.channelCount) sr=\(recordingFormat.sampleRate)")
            recognitionRequest = nil
            return
        }

        // Install tap — capture `request` directly to avoid @MainActor crossing
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        engine.prepare()

        do {
            try engine.start()
        } catch {
            print("[VoiceDictation] Failed to start audio engine: \(error)")
            inputNode.removeTap(onBus: 0)
            audioEngine = nil
            recognitionRequest = nil
            return
        }

        // Start recognition task AFTER engine is running
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let result {
                    self.currentText = result.bestTranscription.formattedString
                }

                if result?.isFinal == true || error != nil {
                    self.stopDictation()
                }
            }
        }

        state = .listening
        print("[VoiceDictation] Dictation started successfully")
    }
}
