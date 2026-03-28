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

    private var audioEngine = AVAudioEngine()

    // iOS 26+ SpeechAnalyzer
    private var speechAnalyzer: Any? // Type-erased to avoid @available on stored property
    private var analyzerTask: Task<Void, Never>?

    // iOS 17-25 fallback
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

    // MARK: - Start Dictation

    func startDictation() {
        guard state == .idle, isAuthorized else { return }

        currentText = ""

        if #available(iOS 26.0, *) {
            startSpeechAnalyzer()
        } else {
            startSFSpeechRecognizer()
        }
    }

    // MARK: - Stop Dictation

    func stopDictation() {
        state = .finishing

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        if #available(iOS 26.0, *) {
            analyzerTask?.cancel()
            analyzerTask = nil
            speechAnalyzer = nil
        } else {
            recognitionRequest?.endAudio()
            recognitionRequest = nil
            recognitionTask?.cancel()
            recognitionTask = nil
            speechRecognizer = nil
        }

        state = .idle
    }

    // MARK: - iOS 26+ SpeechAnalyzer

    @available(iOS 26.0, *)
    private func startSpeechAnalyzer() {
        let transcriber = DictationTranscriber(
            locale: .current,
            preset: .progressiveShortDictation
        )

        do {
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0)

            // Create async stream of AnalyzerInput from audio engine
            let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                let input = AnalyzerInput(buffer: buffer)
                continuation.yield(input)
            }

            let analyzer = SpeechAnalyzer(
                inputSequence: stream,
                modules: [transcriber]
            )

            speechAnalyzer = analyzer
            audioEngine.prepare()
            try audioEngine.start()
            state = .listening

            // Consume results
            analyzerTask = Task {
                do {
                    for try await result in transcriber.results {
                        let text = String(result.text.characters)
                        self.currentText = text
                    }
                } catch {
                    if !Task.isCancelled {
                        print("[VoiceDictation] SpeechAnalyzer error: \(error)")
                    }
                }
                self.state = .idle
            }

            print("[VoiceDictation] Started SpeechAnalyzer dictation")
        } catch {
            print("[VoiceDictation] Failed to start SpeechAnalyzer: \(error)")
            state = .idle
        }
    }

    // MARK: - iOS 17-25 SFSpeechRecognizer Fallback

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

        do {
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            state = .listening
            print("[VoiceDictation] Started SFSpeechRecognizer fallback")
        } catch {
            print("[VoiceDictation] Failed to start audio engine: \(error)")
            stopDictation()
        }
    }
}
