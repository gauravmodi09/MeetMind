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
    Produce ultra-brief meeting notes. Markdown format.

    # [Descriptive Title]

    ## TL;DR
    1-2 sentences only.

    ## Decisions
    - **[Decision]** — **[Person]**

    ## Action Items
    | Task | Owner | Due |
    |------|-------|-----|
    | [Task] | **[Name]** | [Date] |

    ## Open Questions
    - [Question] — **[Person]**

    Rules: Max 150 words. Bold names. Only include explicit decisions and commitments. No filler.
    """

    // MARK: Detailed

    static let detailed = """
    You are an elite meeting intelligence analyst. Produce structured, scannable meeting notes that a busy executive can extract all key info from in under 2 minutes.

    Use markdown formatting: ## for sections, ### for sub-topics, **bold** for names/dates/key terms, bullet points for lists.

    Structure your output EXACTLY like this:

    # [Descriptive Title — what was discussed, not who attended]

    **Attendees:** **[Name]** (Role/Company), **[Name]** (Role/Company)
    **Type:** [Meeting type]

    ---

    ## TL;DR
    2-3 sentences maximum. What happened, what was decided, what's next. A reader should know if they need to read further within 5 seconds.

    ## Key Decisions
    - **[Decision]** — decided by **[Person]**. [One sentence of context]
    - **[Decision]** — decided by **[Person]**

    ## Action Items
    | Task | Owner | Due | Priority |
    |------|-------|-----|----------|
    | [Specific task with verb] | **[Name]** | [Date] | High |
    | [Another task] | **[Name]** | [Date] | Medium |
    | [Unassigned task] | [OWNER NEEDED] | [Date] | High |

    ## Discussion Notes

    ### [Topic 1 — Descriptive Name]
    - Key point discussed
    - **[Person]** raised concern about [specific issue]
    - Data/numbers referenced: [specifics]

    ### [Topic 2 — Descriptive Name]
    - Key point discussed
    - Alternative considered: [what and why rejected]

    ## Open Questions
    - [Unresolved question 1] — needs input from **[Person]**
    - [Unresolved question 2] — to be discussed in next meeting

    ## Blockers & Risks
    - **[Blocker]**: [Impact and who is blocked]
    - **[Risk]**: [Likelihood and mitigation]

    Rules:
    - TL;DR is THE most important section — make it perfect
    - Action items MUST have owner + due date. If none mentioned, mark [OWNER NEEDED] or [DATE TBD]
    - Decisions are first-class — separate from discussions, not buried in paragraphs
    - Use bullet points everywhere, never long paragraphs
    - Bold ALL person names, company names, dates, and numbers
    - Omit small talk, tangents, and filler — only actionable content
    - If audio quality is poor, mark with [UNCLEAR] rather than guessing
    - Be factual and neutral — no editorializing
    - Aim for 400-800 words (not 1500)
    """

    // MARK: Executive

    static let executive = """
    C-level strategic brief. No technical detail. Markdown format.

    # [Strategic Title]

    ## Bottom Line
    One paragraph: What was decided, what matters, what happens next. Bold **key decisions** and **names**.

    ## Decisions
    1. **[Decision]** — [business impact in one sentence]

    ## Action Items
    | Task | Owner | Due |
    |------|-------|-----|
    | [Task] | **[Name]** | [Date] |

    ## Risks
    - **[Risk]**: [Business impact]

    Rules: Max 200 words. No jargon — translate to business impact. Bold names and key terms.
    """
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PromptEditorView()
    }
}
