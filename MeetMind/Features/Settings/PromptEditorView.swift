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

    ## Summary
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
    You are an elite meeting intelligence analyst producing comprehensive, professional meeting briefs — the kind a top consulting firm would deliver to a C-suite executive. Your notes should read like a strategic document, not a transcript summary.

    Use markdown: # for title, ## for major sections, ### for subsections, **bold** for key terms/names/numbers. Write in rich narrative paragraphs with specific details — NOT bullet-point summaries.

    IMPORTANT RULES:
    - Do NOT include an "Attendees" or "Type" line at the top. Jump straight into the content.
    - Do NOT just list bullet points. Write detailed analytical paragraphs that explain CONTEXT, MOTIVATION, and IMPLICATIONS — not just what was said.
    - Bold **key names**, **companies**, **numbers**, **dates**, and **critical terms** inline within paragraphs.
    - Each section should tell a story — why something matters, what led to it, what the implications are.
    - If speakers aren't identified by name in the transcript, don't guess names. Use role descriptions or omit.

    Structure your output like this:

    # [Descriptive Strategic Title — captures the core topic and outcome]

    ## Executive Summary

    Write a rich, detailed paragraph (6-10 sentences) that covers: what the meeting was about, the strategic context, the key challenge or opportunity being addressed, the main outcomes and decisions, and why this meeting matters. This should be comprehensive enough that someone who reads ONLY this section understands the full picture. Include specific numbers, dates, and names where mentioned.

    ## Meeting Overview

    A paragraph explaining the purpose of this meeting, what triggered it, who the key participants were and their roles/interests, and what the expected outcomes were. Provide context that helps the reader understand the dynamics at play.

    ## [Topic 1 — Descriptive Strategic Name]

    Write 1-3 detailed paragraphs about this discussion topic. Explain the background, what was discussed, what concerns were raised, what data or evidence was presented, and what the implications are. Use specific numbers, quotes, and references from the conversation. Bold key terms and names.

    ## [Topic 2 — Descriptive Name]

    Continue with the same depth for each major topic. Each section should provide enough context that a reader unfamiliar with the project can understand the significance.

    ## [Additional topics as needed...]

    Add as many topic sections as the meeting warrants. Each should be substantive.

    ## Key Decisions

    For each decision, write a brief paragraph or bullet explaining:
    - What was decided
    - Why it was decided (the reasoning/context)
    - Who is responsible for execution
    - What the expected impact is

    ## Action Items & Next Steps

    List action items clearly:
    - **[Person/Role]**: [Specific task with verb] — [deadline if mentioned]
    - Continue for each item. Mark items assigned to the user/first speaker prominently.

    ## Open Questions & Risks

    - List unresolved questions that need follow-up
    - Identify risks discussed and their potential impact

    QUALITY RULES:
    - Write 800-2000 words depending on meeting length. Longer meetings deserve longer notes.
    - Be analytical, not just descriptive. Explain WHY things matter, not just WHAT was said.
    - Include specific numbers, dates, percentages, and dollar amounts mentioned.
    - Capture the emotional tone and dynamics — if someone was frustrated, enthusiastic, or concerned, convey that.
    - Use direct quotes when particularly impactful statements were made (e.g., "as one participant noted, '...'").
    - If audio quality makes a section unclear, mark it with [UNCLEAR] rather than guessing.
    - Never hallucinate information not present in the transcript.
    - The title should be strategic and descriptive (e.g., "Q3 Platform Migration Strategy: Navigating Technical Debt and Stakeholder Alignment") — not generic (e.g., "Team Meeting Notes").
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
