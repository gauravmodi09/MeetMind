import SwiftUI

struct NotepadView: View {
    @Binding var notepadContent: String
    let templateSections: String?
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(MMColors.primary)
                    .font(.system(size: 14))

                Text("Notepad")
                    .font(MMTypography.footnoteMedium)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                // Auto-save indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(MMColors.success)
                        .frame(width: 6, height: 6)
                    Text("Auto-saved")
                        .font(MMTypography.caption2)
                        .foregroundColor(.white.opacity(0.35))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Editor
            ZStack(alignment: .topLeading) {
                if notepadContent.isEmpty {
                    Text(templateSections ?? "Start typing your notes...")
                        .font(MMTypography.body)
                        .foregroundColor(.white.opacity(0.2))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $notepadContent)
                    .font(MMTypography.body)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .tint(MMColors.primary)
                    .focused($isFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .accessibilityLabel("Meeting notepad")
            }
            .frame(maxHeight: .infinity)

            // Toolbar above keyboard
            if isFocused {
                NotepadToolbar(text: $notepadContent, isFocused: $isFocused)
            }
        }
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isFocused ? MMColors.primary.opacity(0.3) : Color.white.opacity(0.06),
                    lineWidth: 1
                )
        )
        .onAppear {
            if notepadContent.isEmpty, let sections = templateSections {
                notepadContent = sections
            }
        }
    }
}
