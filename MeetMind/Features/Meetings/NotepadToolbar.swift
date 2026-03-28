import SwiftUI

struct NotepadToolbar: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        HStack(spacing: 16) {
            toolbarButton("bold", label: "Bold") {
                insertMarkdown(prefix: "**", suffix: "**")
            }

            toolbarButton("list.bullet", label: "Bullet") {
                insertBullet()
            }

            toolbarButton("textformat.size", label: "Heading") {
                insertHeading()
            }

            // Voice dictation
            DictationButton(text: $text) { rawText in
                try? await TextCleanupService.shared.cleanupDictatedText(rawText).cleanedText
            }

            Spacer()

            toolbarButton("keyboard.chevron.compact.down", label: "Dismiss") {
                isFocused = false
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(MMColors.backgroundElevated)
    }

    private func toolbarButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.08))
                .cornerRadius(8)
        }
        .accessibilityLabel(label)
    }

    private func insertMarkdown(prefix: String, suffix: String) {
        text.append(prefix + suffix)
    }

    private func insertBullet() {
        if text.isEmpty || text.hasSuffix("\n") {
            text.append("• ")
        } else {
            text.append("\n• ")
        }
    }

    private func insertHeading() {
        if text.isEmpty || text.hasSuffix("\n") {
            text.append("## ")
        } else {
            text.append("\n## ")
        }
    }
}
