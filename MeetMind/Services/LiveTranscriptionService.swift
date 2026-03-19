import Speech
import AVFoundation
import Combine

/// Real-time speech transcription using iOS Speech framework.
/// This is for DISPLAY ONLY during recording — the final transcript
/// still comes from Groq Whisper for accuracy.
@MainActor
class LiveTranscriptionService: ObservableObject {
    static let shared = LiveTranscriptionService()

    // MARK: - Published State

    @Published var liveText: String = ""
    @Published var isTranscribing: Bool = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    // MARK: - Private

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()

    // MARK: - Init

    private init() {
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                Task { @MainActor [weak self] in
                    self?.authorizationStatus = status
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }

    // MARK: - Live Transcription

    /// Starts live transcription using a separate AVAudioEngine input tap.
    /// This runs alongside AVAudioRecorder which writes to disk independently.
    /// Both use the shared AVAudioSession but operate on separate pipelines.
    func startLiveTranscription() {
        guard !isTranscribing else { return }

        guard authorizationStatus == .authorized else {
            print("[LiveTranscription] Speech recognition not authorized (status: \(authorizationStatus.rawValue))")
            return
        }

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            print("[LiveTranscription] Speech recognizer not available")
            return
        }

        // Clean up any previous session
        stopLiveTranscription()

        do {
            try startRecognition(with: speechRecognizer)
            isTranscribing = true
            liveText = ""
            print("[LiveTranscription] Started live transcription")
        } catch {
            print("[LiveTranscription] Failed to start: \(error.localizedDescription)")
            cleanupResources()
        }
    }

    /// Stops the audio engine and cancels recognition.
    func stopLiveTranscription() {
        guard isTranscribing || audioEngine.isRunning || recognitionTask != nil else { return }

        // Stop the audio engine tap first
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        // End the recognition request so the task can finish
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // Cancel any in-flight recognition
        recognitionTask?.cancel()
        recognitionTask = nil

        isTranscribing = false
        print("[LiveTranscription] Stopped live transcription")
    }

    // MARK: - Private

    private func startRecognition(with recognizer: SFSpeechRecognizer) throws {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        // On-device recognition when available (iOS 13+) for lower latency
        if #available(iOS 13, *) {
            request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        }

        recognitionRequest = request

        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let result {
                    self.liveText = result.bestTranscription.formattedString
                }

                if let error {
                    // Don't log cancellation errors — they're expected on stop
                    let nsError = error as NSError
                    if nsError.domain != "kAFAssistantErrorDomain" || nsError.code != 216 {
                        print("[LiveTranscription] Recognition error: \(error.localizedDescription)")
                    }
                }

                // If the result is final or we got an error, the task is done
                if result?.isFinal == true || error != nil {
                    self.cleanupResources()
                }
            }
        }

        // Install tap on audio engine's input node
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Remove any existing tap before installing a new one
        inputNode.removeTap(onBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    private func cleanupResources() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest = nil
        recognitionTask = nil
        isTranscribing = false
    }
}
