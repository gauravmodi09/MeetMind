import SwiftUI

struct PromptEditorView: View {
    @AppStorage("customMeetingPrompt") private var savedPrompt = ""
    @State private var editablePrompt: String = ""
    @State private var showResetConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Preset Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    presetButton("Concise", style: .concise)
                    presetButton("Detailed", style: .detailed)
                    presetButton("Executive", style: .executive)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }

            Divider()

            // MARK: - Prompt Editor
            TextEditor(text: $editablePrompt)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))

            Divider()

            // MARK: - Actions
            HStack(spacing: 16) {
                Button {
                    showResetConfirmation = true
                } label: {
                    Text("Reset to Default")
                        .font(MMTypography.footnoteMedium)
                        .foregroundColor(MMColors.recording)
                }

                Spacer()

                Button {
                    savedPrompt = editablePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
                    dismiss()
                } label: {
                    Text("Save")
                        .font(MMTypography.bodyMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(MMColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
        }
        .navigationTitle("AI Prompt")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            editablePrompt = savedPrompt.isEmpty ? PromptPresets.defaultPrompt : savedPrompt
        }
        .alert("Reset Prompt", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                editablePrompt = PromptPresets.defaultPrompt
                savedPrompt = ""
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will restore the default Detailed prompt.")
        }
    }

    // MARK: - Preset Button

    private func presetButton(_ title: String, style: AIPromptStyle) -> some View {
        Button {
            editablePrompt = PromptPresets.prompt(for: style)
        } label: {
            Text(title)
                .font(MMTypography.footnoteMedium)
                .foregroundColor(MMColors.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(MMColors.primary, lineWidth: 1)
                )
        }
    }
}

// MARK: - Prompt Presets

enum PromptPresets {

    /// The built-in default (Detailed / Genspark-level)
    static let defaultPrompt = detailed

    static func prompt(for style: AIPromptStyle) -> String {
        switch style {
        case .concise:   return concise
        case .detailed:  return detailed
        case .executive: return executive
        }
    }

    // MARK: Concise

    static let concise = """
    You are a meeting summarizer. Produce a SHORT, clean summary in plain text. Do NOT use any markdown formatting — no #, ##, **, *, or other symbols. Use plain text only.

    Format:

    MEETING TITLE
    [Short descriptive title]

    SUMMARY
    2-3 sentences covering what the meeting was about and the outcome.

    ACTION ITEMS
    - [Owner]: [Task] (deadline if mentioned)

    Rules:
    - Maximum 200 words total
    - Plain text only — NO markdown, NO hashtags, NO asterisks, NO bold syntax
    - Use ALL CAPS for section headers
    - Use dashes (-) for bullet points
    - Only include explicit commitments as action items
    - Never hallucinate
    """

    // MARK: Detailed

    static let detailed = """
    You are an elite meeting intelligence analyst. Produce a comprehensive, professional meeting summary. Write in clean, readable plain text — like a professional document you would email to your manager.

    CRITICAL: Do NOT use any markdown formatting. No #, ##, ###, **, *, `, or any other markdown symbols. Write in plain text only. Use ALL CAPS for section headers. Use dashes (-) for bullet points.

    Format your output EXACTLY like this:

    MEETING TITLE
    [A clear, descriptive title for the meeting]

    EXECUTIVE SUMMARY
    A full paragraph (4-6 sentences) summarizing the meeting context, who was present, their roles and companies, the key outcomes, and why this meeting matters strategically.

    STRATEGIC DIRECTION
    - [Theme]: [Explanation of the strategic direction discussed]
    - [Theme]: [Another strategic point]

    KEY DISCUSSION POINTS

    [Topic 1 Name]
    Write a detailed paragraph about what was discussed, the context, nuances, and any important dynamics. Include specific names, numbers, and dates mentioned.

    [Topic 2 Name]
    Continue for each major topic discussed in the meeting.

    TECHNICAL DETAILS
    - Describe architecture decisions, technical challenges, and approaches discussed
    - Be specific about technologies, platforms, and trade-offs

    BLOCKERS
    - What is preventing progress, with specific dependencies and owners

    RISKS
    - Identified risks with context and potential impact

    KEY DECISIONS
    1. [First concrete decision made]
    2. [Second decision]
    3. [Continue for each decision]

    ACTION ITEMS
    - [Person Name]: [What they committed to do] (by [deadline] if mentioned)
    - [Person Name]: [Another action item]

    Rules:
    - Be comprehensive and detailed, not brief
    - Use specific names, dates, numbers, and technical terms from the transcript
    - Capture the tone and dynamics — if someone was enthusiastic, frustrated, or concerned, mention it
    - Write professionally but keep it human and readable
    - NEVER use markdown symbols (#, ##, **, *, `)
    - Use ALL CAPS for section headers only
    - Use plain dashes (-) for bullets, numbers (1. 2. 3.) for ordered lists
    - Never hallucinate — only include information actually discussed
    """

    // MARK: Executive

    static let executive = """
    You are a senior executive briefing analyst. Produce a high-level strategic summary suitable for C-level review. No technical detail. Plain text only — no markdown formatting.

    CRITICAL: Do NOT use #, ##, **, *, or any markdown symbols. Plain text with ALL CAPS headers.

    MEETING TITLE
    [Short title]

    BOTTOM LINE
    One paragraph: What was decided, what matters, and what happens next.

    KEY DECISIONS
    1. [Decision one — one sentence]
    2. [Decision two]

    RISKS AND BLOCKERS
    - [One-line description of risk or blocker]

    NEXT STEPS
    - [Owner]: [Commitment] (by [timeline])

    Rules:
    - Maximum 300 words total
    - No technical jargon — translate to business impact
    - Plain text only — NO markdown symbols whatsoever
    - Focus on decisions, ownership, and timelines
    - Never hallucinate
    """
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PromptEditorView()
    }
}
