import SwiftUI

struct DictationButton: View {
    @StateObject private var dictation = VoiceDictationService()
    @Binding var text: String

    let onCleanup: ((String) async -> String?)?
    @State private var isCleaning = false
    @State private var rawTextBeforeCleanup: String?
    @State private var showUndoCleanup = false

    init(text: Binding<String>, onCleanup: ((String) async -> String?)? = nil) {
        self._text = text
        self.onCleanup = onCleanup
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                if dictation.state == .listening {
                    stopAndCleanup()
                } else {
                    startDictation()
                }
            } label: {
                ZStack {
                    if dictation.state == .listening {
                        // Pulsing ring
                        Circle()
                            .stroke(MMColors.recording.opacity(0.3), lineWidth: 2)
                            .frame(width: 42, height: 42)
                            .scaleEffect(isCleaning ? 1.0 : 1.3)
                            .opacity(isCleaning ? 0 : 0.6)
                            .animation(
                                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                                value: dictation.state
                            )
                    }

                    Image(systemName: dictation.state == .listening ? "mic.fill" : "mic")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(dictation.state == .listening ? MMColors.recording : .white.opacity(0.7))
                        .frame(width: 36, height: 36)
                        .background(
                            dictation.state == .listening
                                ? MMColors.recording.opacity(0.15)
                                : Color.white.opacity(0.08)
                        )
                        .cornerRadius(8)
                }
            }
            .accessibilityLabel(dictation.state == .listening ? "Stop dictation" : "Start dictation")
            .disabled(isCleaning)

            // Undo cleanup
            if showUndoCleanup {
                Button {
                    if let raw = rawTextBeforeCleanup {
                        text = raw
                        rawTextBeforeCleanup = nil
                        showUndoCleanup = false
                    }
                } label: {
                    Text("Undo cleanup")
                        .font(MMTypography.caption2)
                        .foregroundColor(MMColors.primary)
                }
                .padding(.top, 4)
            }
        }
        .onChange(of: dictation.currentText) { _, newText in
            if dictation.state == .listening && !newText.isEmpty {
                text = newText
            }
        }
        .task {
            if !dictation.isAuthorized {
                _ = await dictation.requestAuthorization()
            }
        }
    }

    private func startDictation() {
        showUndoCleanup = false
        rawTextBeforeCleanup = nil
        dictation.startDictation()
    }

    private func stopAndCleanup() {
        dictation.stopDictation()

        guard let onCleanup, !text.isEmpty else { return }

        isCleaning = true
        let textToClean = text

        Task {
            if let cleaned = await onCleanup(textToClean) {
                rawTextBeforeCleanup = textToClean
                text = cleaned
                showUndoCleanup = true
            }
            isCleaning = false
        }
    }
}
