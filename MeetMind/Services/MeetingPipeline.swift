import Foundation
import Combine

@MainActor
class MeetingPipeline: ObservableObject {

    // MARK: - Processing State

    enum ProcessingState: Equatable {
        case idle
        case compressing
        case splitting
        case transcribing(progress: Double)
        case cleaning
        case structuring
        case complete(MeetingBrief)
        case failed(Error)

        static func == (lhs: ProcessingState, rhs: ProcessingState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.compressing, .compressing): return true
            case (.splitting, .splitting): return true
            case (.transcribing(let a), .transcribing(let b)): return a == b
            case (.cleaning, .cleaning): return true
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

    /// Full post-recording pipeline: compress -> split -> transcribe -> clean -> validate -> structure -> brief.
    func process(audioURL: URL, userNotes: String?, template: MeetingTemplate = .general) async throws -> MeetingBrief {
        do {
            // Step 1: Compress if needed
            print("[Pipeline] Step 1: Compressing \(audioURL.lastPathComponent)...")
            processingState = .compressing
            let compressedURL = try await recorder.compressAudioIfNeeded(url: audioURL)
            print("[Pipeline] Compression done. File: \(compressedURL.lastPathComponent)")

            // Step 2: Split into chunks if still too large (>24 MB after compression)
            print("[Pipeline] Step 2: Splitting if needed...")
            processingState = .splitting
            let chunks = try await recorder.splitAudioIfNeeded(url: compressedURL)
            print("[Pipeline] Split into \(chunks.count) chunk(s)")

            // Clean up compressed file if it was created
            if compressedURL != audioURL {
                try? FileManager.default.removeItem(at: compressedURL)
            }

            // Step 3: Transcribe all chunks via Whisper (with retry built into performRequest)
            print("[Pipeline] Step 3: Transcribing \(chunks.count) chunk(s) via Groq Whisper...")
            processingState = .transcribing(progress: 0.0)

            let transcription: TranscriptionResult
            if chunks.count == 1 {
                transcription = try await groq.transcribeAudio(fileURL: chunks[0])
            } else {
                transcription = try await groq.transcribeChunks(fileURLs: chunks)
            }

            processingState = .transcribing(progress: 1.0)
            print("[Pipeline] Transcription done. \(transcription.text.count) chars, \(transcription.segments.count) segments")

            // Clean up chunk files
            recorder.cleanupChunks(chunks, originalURL: audioURL)

            // Step 4: Validate transcript quality
            guard !transcription.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw PipelineError.emptyTranscript
            }

            guard groq.isTranscriptUsable(transcription.text) else {
                throw PipelineError.lowQualityTranscript
            }

            // Step 5: Clean transcript (remove filler words, stutters, normalize)
            print("[Pipeline] Step 5: Cleaning transcript...")
            processingState = .cleaning
            let rawTranscript = transcription.text
            let cleanedTranscript = groq.cleanTranscript(rawTranscript)
            let reduction = rawTranscript.count - cleanedTranscript.count
            print("[Pipeline] Cleaned transcript: removed \(reduction) chars of filler/noise")

            // Step 6: Generate structured brief via Llama
            print("[Pipeline] Step 6: Generating brief via Groq Llama...")
            processingState = .structuring
            let brief = try await groq.generateMeetingBrief(
                transcript: cleanedTranscript,
                userNotes: userNotes,
                template: template
            )

            // Store the raw transcript (not cleaned) so the user sees the original
            lastRawTranscript = rawTranscript
            processingState = .complete(brief)
            print("[Pipeline] Pipeline complete! Title: \(brief.title)")
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
    case lowQualityTranscript

    var errorDescription: String? {
        switch self {
        case .emptyTranscript:
            return "No speech detected in recording. The audio may be silent, too short, or not contain recognizable speech."
        case .lowQualityTranscript:
            return "The recording quality was too low to produce a useful transcript. Try recording in a quieter environment or closer to the speakers."
        }
    }
}
