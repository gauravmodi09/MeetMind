import Foundation
import Combine

@MainActor
class MeetingPipeline: ObservableObject {

    // MARK: - Processing State

    enum ProcessingState: Equatable {
        case idle
        case compressing
        case transcribing(progress: Double)
        case structuring
        case complete(MeetingBrief)
        case failed(Error)

        static func == (lhs: ProcessingState, rhs: ProcessingState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.compressing, .compressing): return true
            case (.transcribing(let a), .transcribing(let b)): return a == b
            case (.structuring, .structuring): return true
            case (.complete, .complete): return true
            case (.failed, .failed): return true
            default: return false
            }
        }
    }

    @Published var processingState: ProcessingState = .idle
    var lastRawTranscript: String?

    private let recorder = AudioRecordingService.shared
    private let groq = GroqService.shared

    // MARK: - Process

    /// Full post-recording pipeline: compress -> transcribe -> structure -> return brief.
    func process(audioURL: URL, userNotes: String?, template: MeetingTemplate = .general) async throws -> MeetingBrief {
        do {
            // Step 1: Compress if needed
            print("[Pipeline] Step 1: Compressing \(audioURL.lastPathComponent)...")
            processingState = .compressing
            let fileToUpload = try await recorder.compressAudioIfNeeded(url: audioURL)
            print("[Pipeline] Compression done. File: \(fileToUpload.lastPathComponent)")

            // Step 2: Transcribe via Whisper
            print("[Pipeline] Step 2: Transcribing via Groq Whisper...")
            processingState = .transcribing(progress: 0.0)
            let transcription = try await groq.transcribeAudio(fileURL: fileToUpload)
            processingState = .transcribing(progress: 1.0)
            print("[Pipeline] Transcription done. \(transcription.text.count) chars")

            // Clean up compressed file if it differs from original
            if fileToUpload != audioURL {
                try? FileManager.default.removeItem(at: fileToUpload)
            }

            guard !transcription.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw PipelineError.emptyTranscript
            }

            // Step 3: Generate structured brief via Llama
            print("[Pipeline] Step 3: Generating brief via Groq Llama...")
            processingState = .structuring
            let brief = try await groq.generateMeetingBrief(
                transcript: transcription.text,
                userNotes: userNotes,
                template: template
            )

            lastRawTranscript = transcription.text
            processingState = .complete(brief)
            return brief

        } catch {
            print("[Pipeline] FAILED at state \(processingState): \(error)")
            processingState = .failed(error)
            throw error
        }
    }

    /// Resets state back to idle.
    func reset() {
        processingState = .idle
    }
}

// MARK: - Pipeline Errors

enum PipelineError: LocalizedError {
    case emptyTranscript

    var errorDescription: String? {
        switch self {
        case .emptyTranscript:
            return "No speech detected in recording. The audio may be silent, too short, or not contain recognizable speech."
        }
    }
}
