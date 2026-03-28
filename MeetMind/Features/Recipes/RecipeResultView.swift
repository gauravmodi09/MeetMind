import SwiftUI

struct RecipeResultView: View {
    let recipe: MeetingRecipe
    let meeting: Meeting
    @Environment(\.dismiss) private var dismiss
    @State private var result = ""
    @State private var isLoading = true
    @State private var error: String?
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                MMColors.background.ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if let error {
                    errorView(error)
                } else {
                    resultContent
                }
            }
            .navigationTitle(recipe.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                if !isLoading && error == nil {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            copyResult()
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        Button {
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [result])
            }
        }
        .task {
            await executeRecipe()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Applying \"\(recipe.name)\"...")
                .font(.subheadline)
                .foregroundColor(MMColors.textSecondary)
            Text(meeting.title)
                .font(.caption)
                .foregroundColor(MMColors.textTertiary)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(MMColors.warning)
            Text("Recipe Failed")
                .font(.headline)
                .foregroundColor(MMColors.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(MMColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try Again") {
                isLoading = true
                error = nil
                Task { await executeRecipe() }
            }
            .buttonStyle(.borderedProminent)
            .tint(MMColors.primary)
        }
    }

    private var resultContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                meetingContextCard
                ForEach(Array(parseSections(result).enumerated()), id: \.offset) { _, section in
                    sectionCard(section)
                }
            }
            .padding(16)
        }
    }

    private var meetingContextCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(MMColors.primary)
                .frame(width: 40, height: 40)
                .background(MMColors.primaryLight)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(meeting.title)
                    .font(MMTypography.footnoteMedium)
                    .foregroundColor(MMColors.textPrimary)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(meeting.date, style: .date)
                        .font(MMTypography.caption1)
                        .foregroundColor(MMColors.textTertiary)
                    if meeting.duration > 0 {
                        Text("·")
                            .foregroundColor(MMColors.textTertiary)
                        Text(formatDuration(meeting.duration))
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.textTertiary)
                    }
                }
            }
            Spacer()
        }
        .padding(14)
        .background(MMColors.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(MMColors.border, lineWidth: 1)
        )
    }

    // MARK: - Markdown Section Parser

    private struct MarkdownSection {
        let title: String?
        let content: String
        let icon: String?
    }

    private func parseSections(_ text: String) -> [MarkdownSection] {
        let lines = text.components(separatedBy: "\n")
        var sections: [MarkdownSection] = []
        var currentTitle: String? = nil
        var currentLines: [String] = []

        for line in lines {
            if line.hasPrefix("## ") || line.hasPrefix("# ") {
                if !currentLines.isEmpty || currentTitle != nil {
                    let content = currentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                    if !content.isEmpty {
                        sections.append(MarkdownSection(
                            title: currentTitle,
                            content: content,
                            icon: iconForTitle(currentTitle)
                        ))
                    }
                }
                currentTitle = line.replacingOccurrences(of: "## ", with: "")
                    .replacingOccurrences(of: "# ", with: "")
                    .trimmingCharacters(in: .whitespaces)
                currentLines = []
            } else if line == "---" {
                continue
            } else {
                currentLines.append(line)
            }
        }

        let content = currentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if !content.isEmpty {
            sections.append(MarkdownSection(
                title: currentTitle,
                content: content,
                icon: iconForTitle(currentTitle)
            ))
        }

        return sections
    }

    private func iconForTitle(_ title: String?) -> String? {
        guard let t = title?.lowercased() else { return nil }
        if t.contains("summary") || t.contains("overview") { return "doc.text" }
        if t.contains("decision") { return "checkmark.seal" }
        if t.contains("action") || t.contains("next step") || t.contains("task") { return "checklist" }
        if t.contains("question") || t.contains("risk") { return "exclamationmark.triangle" }
        if t.contains("feedback") || t.contains("strength") { return "star" }
        if t.contains("objection") || t.contains("concern") { return "hand.raised" }
        if t.contains("email") || t.contains("follow") { return "envelope" }
        if t.contains("quote") { return "quote.opening" }
        return "text.justify.leading"
    }

    @ViewBuilder
    private func sectionCard(_ section: MarkdownSection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title = section.title {
                HStack(spacing: 8) {
                    if let icon = section.icon {
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(MMColors.primary)
                    }
                    Text(title)
                        .font(MMTypography.headline)
                        .foregroundColor(MMColors.textPrimary)
                    Spacer()

                    Button {
                        #if canImport(UIKit)
                        UIPasteboard.general.string = "\(title)\n\n\(section.content)"
                        #endif
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(MMColors.textTertiary)
                    }
                }
            }

            renderMarkdownContent(section.content)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MMColors.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(MMColors.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func renderMarkdownContent(_ text: String) -> some View {
        let lines = text.components(separatedBy: "\n")
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty {
                    Spacer().frame(height: 4)
                } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("• ") {
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(MMColors.primary)
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        renderInlineMarkdown(String(trimmed.dropFirst(2)))
                    }
                } else if trimmed.hasPrefix("### ") {
                    Text(trimmed.replacingOccurrences(of: "### ", with: ""))
                        .font(MMTypography.footnoteMedium)
                        .foregroundColor(MMColors.textPrimary)
                        .padding(.top, 4)
                } else {
                    renderInlineMarkdown(trimmed)
                }
            }
        }
    }

    private func renderInlineMarkdown(_ text: String) -> Text {
        var result = Text("")
        var remaining = text

        while let boldStart = remaining.range(of: "**") {
            let before = String(remaining[remaining.startIndex..<boldStart.lowerBound])
            if !before.isEmpty {
                result = result + Text(before).foregroundColor(MMColors.textSecondary)
            }
            remaining = String(remaining[boldStart.upperBound...])
            if let boldEnd = remaining.range(of: "**") {
                let boldText = String(remaining[remaining.startIndex..<boldEnd.lowerBound])
                result = result + Text(boldText).bold().foregroundColor(MMColors.textPrimary)
                remaining = String(remaining[boldEnd.upperBound...])
            } else {
                // Unclosed bold marker — render ** as literal text
                result = result + Text("**").foregroundColor(MMColors.textSecondary)
            }
        }
        if !remaining.isEmpty {
            result = result + Text(remaining).foregroundColor(MMColors.textSecondary)
        }
        return result.font(MMTypography.subheadline)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    // MARK: - Actions

    private func executeRecipe() async {
        guard let transcript = meeting.rawTranscript, !transcript.isEmpty else {
            error = "This meeting has no transcript available."
            isLoading = false
            return
        }

        do {
            result = try await GroqService.shared.executeRecipe(
                prompt: recipe.prompt,
                transcript: transcript
            )
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    private func copyResult() {
        #if canImport(UIKit)
        UIPasteboard.general.string = result
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result, forType: .string)
        #endif
    }
}

// MARK: - Preview

#Preview {
    RecipeResultView(
        recipe: MeetingRecipe.builtIn[0],
        meeting: Meeting(title: "Sample Meeting", status: .complete, rawTranscript: "Hello world")
    )
}
