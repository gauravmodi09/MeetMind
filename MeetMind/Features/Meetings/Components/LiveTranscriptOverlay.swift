import SwiftUI

/// A semi-transparent overlay that shows the last few lines of live transcription text.
/// Designed to sit at the bottom of the RecordingView during active recording.
struct LiveTranscriptOverlay: View {
    @ObservedObject var transcriptionService: LiveTranscriptionService

    /// Number of trailing lines to display
    private let maxLines: Int = 3

    var body: some View {
        Group {
            if transcriptionService.isTranscribing && !transcriptionService.liveText.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(MMColors.success)
                            .frame(width: 6, height: 6)
                            .opacity(pulseOpacity)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                    pulseOpacity = 0.3
                                }
                            }
                            .onDisappear {
                                pulseOpacity = 1.0
                            }

                        Text("Live Transcript")
                            .font(MMTypography.caption1Medium)
                            .foregroundColor(MMColors.textTertiary)
                    }

                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            Text(tailText)
                                .font(MMTypography.subheadline)
                                .foregroundColor(MMColors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id("transcriptEnd")
                        }
                        .frame(maxHeight: 72)
                        .onChange(of: transcriptionService.liveText) { _ in
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("transcriptEnd", anchor: .bottom)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(MMColors.glassStroke, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: transcriptionService.isTranscribing)
        .animation(.easeInOut(duration: 0.15), value: transcriptionService.liveText)
    }

    // MARK: - Computed

    /// Extracts the last N lines from the live text to keep the overlay compact.
    private var tailText: String {
        let lines = transcriptionService.liveText
            .components(separatedBy: .newlines)
            .flatMap { line -> [String] in
                // Also split long single lines by approximate word wrapping
                // to provide a more accurate "last 3 lines" feel
                let words = line.split(separator: " ")
                if words.count <= 12 { return [line] }
                // Chunk into ~12-word segments
                var chunks: [String] = []
                var current: [Substring] = []
                for word in words {
                    current.append(word)
                    if current.count >= 12 {
                        chunks.append(current.joined(separator: " "))
                        current = []
                    }
                }
                if !current.isEmpty {
                    chunks.append(current.joined(separator: " "))
                }
                return chunks
            }
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        return lines.suffix(maxLines).joined(separator: "\n")
    }

    // MARK: - Animation State

    @State private var pulseOpacity: Double = 1.0

}

// MARK: - Preview

#if DEBUG
struct LiveTranscriptOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            MMColors.background
                .ignoresSafeArea()

            VStack {
                Spacer()
                LiveTranscriptOverlay(
                    transcriptionService: .shared
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}
#endif
