# MeetMind Meeting Notes Enhancement Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform MeetMind's meeting notes from basic summaries into industry-best MOM format, fix the chat system to be fast/intelligent/useful, add meeting deletion, and stop storing audio files.

**Architecture:** Upgrade the Groq Llama prompt to produce structured, scannable notes following the "Golden Template" format (TL;DR → Decisions → Action Items table → Discussion → Open Questions). Rewrite the chat system with a smart pre-processor that detects query type (stats/search/analysis) and responds with formatted, direct answers. Add swipe-to-delete on meeting cards with confirmation.

**Tech Stack:** SwiftUI, Groq Whisper + Llama 3.3 70B, Core Data, iOS NaturalLanguage framework

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `Services/GroqService.swift` | Modify | New meeting notes prompt, smart chat pre-processor |
| `Features/Settings/PromptEditorView.swift` | Modify | New "Golden Template" prompt preset |
| `Features/Meetings/MeetingDetailView.swift` | Modify | New notes renderer with TL;DR, decisions, action items table, open questions |
| `Features/Meetings/MeetingsView.swift` | Modify | Add swipe-to-delete, delete confirmation |
| `Features/Meetings/Components/MeetingCard.swift` | Modify | Add swipe action for delete |
| `Features/Chat/MeetingChatView.swift` | Rewrite | Smart query detection, formatted responses, stats answers |
| `Features/Meetings/MeetingChatSheet.swift` | Modify | Better context building, cleaner responses |
| `Services/MeetingService.swift` | Modify | Skip audio storage option, enhance delete |
| `Services/MeetingPipeline.swift` | Modify | Optional audio deletion after transcription |
| `Services/AudioRecordingService.swift` | Modify | Add option to delete audio after processing |

---

### Task 1: Upgrade Meeting Notes Prompt to Golden Template Format

**Files:**
- Modify: `MeetMind/Features/Settings/PromptEditorView.swift` (lines 137-193, the `detailed` prompt)
- Modify: `MeetMind/Services/GroqService.swift` (lines 279-300, JSON extraction prompt)

- [ ] **Step 1: Replace the detailed prompt with Golden Template format**

In `PromptEditorView.swift`, replace the `detailed` static let with:

```swift
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
```

- [ ] **Step 2: Update the concise prompt**

Replace the `concise` static let:

```swift
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
```

- [ ] **Step 3: Update the executive prompt**

Replace the `executive` static let:

```swift
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
```

- [ ] **Step 4: Update JSON extraction prompt in GroqService**

In `GroqService.swift`, update the JSON extraction prompt (around line 279) to extract open questions:

Add `"openQuestions"` to the JSON schema:
```swift
"openQuestions": ["Unresolved question 1", "Question needing follow-up"]
```

Add to rules:
```
- openQuestions: items raised but NOT resolved, max 5
```

- [ ] **Step 5: Build and verify**

Run: `xcodebuild -scheme MeetMind -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add MeetMind/Features/Settings/PromptEditorView.swift MeetMind/Services/GroqService.swift
git commit -m "feat: upgrade meeting notes to Golden Template format with TL;DR, decisions, action items table"
```

---

### Task 2: Upgrade Meeting Detail View to Render New Format

**Files:**
- Modify: `MeetMind/Features/Meetings/MeetingDetailView.swift` (the `richSummaryText` renderer and sections)

- [ ] **Step 1: Add TL;DR extraction and prominent display**

Add a method to extract TL;DR from the summary markdown:

```swift
private func extractTLDR(from summary: String) -> String? {
    let lines = summary.components(separatedBy: "\n")
    var capturing = false
    var tldr = ""
    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("## TL;DR") || trimmed.hasPrefix("## TLDR") {
            capturing = true
            continue
        }
        if capturing && trimmed.hasPrefix("##") { break }
        if capturing && !trimmed.isEmpty {
            tldr += (tldr.isEmpty ? "" : " ") + trimmed
        }
    }
    return tldr.isEmpty ? nil : tldr
}
```

- [ ] **Step 2: Add TL;DR card at the top of the detail view**

Before the summary section, add a highlighted TL;DR card:

```swift
// TL;DR card — most important, shown first
if let summary = meeting.briefSummary, let tldr = extractTLDR(from: summary) {
    VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 14))
                .foregroundColor(MMColors.warning)
            Text("TL;DR")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(MMColors.warning)
        }
        renderBoldText(tldr)
    }
    .padding(16)
    .background(MMColors.warning.opacity(0.08))
    .cornerRadius(16)
    .overlay(
        RoundedRectangle(cornerRadius: 16)
            .stroke(MMColors.warning.opacity(0.2), lineWidth: 1)
    )
    .padding(.horizontal, 16)
}
```

- [ ] **Step 3: Add Open Questions section**

After the action items section, add:

```swift
// Open Questions
if let summary = meeting.briefSummary {
    let questions = extractOpenQuestions(from: summary)
    if !questions.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Open Questions", icon: "questionmark.circle")
            VStack(spacing: 8) {
                ForEach(questions, id: \.self) { question in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 14))
                            .foregroundColor(MMColors.info)
                            .padding(.top, 2)
                        renderBoldText(question)
                    }
                    .padding(12)
                    .background(MMColors.info.opacity(0.06))
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
```

- [ ] **Step 4: Add markdown table renderer for action items in summary**

Enhance `richSummaryText` to detect and render markdown tables (lines starting with `|`):

```swift
} else if trimmed.hasPrefix("|") && trimmed.hasSuffix("|") && !trimmed.contains("---") {
    // Markdown table row
    let cells = trimmed.split(separator: "|").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    if !cells.isEmpty {
        HStack(spacing: 12) {
            ForEach(Array(cells.enumerated()), id: \.offset) { idx, cell in
                renderBoldText(cell)
                    .frame(maxWidth: .infinity, alignment: idx == 0 ? .leading : .center)
            }
        }
        .padding(.vertical, 4)
    }
}
```

- [ ] **Step 5: Build and verify**

Run: `xcodebuild -scheme MeetMind -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`

- [ ] **Step 6: Commit**

```bash
git add MeetMind/Features/Meetings/MeetingDetailView.swift
git commit -m "feat: add TL;DR card, open questions section, and table rendering to meeting detail view"
```

---

### Task 3: Add Swipe-to-Delete for Meetings

**Files:**
- Modify: `MeetMind/Features/Meetings/MeetingsView.swift` (meeting list)
- Modify: `MeetMind/Features/Meetings/Components/MeetingCard.swift` (add delete callback)
- Modify: `MeetMind/Services/MeetingService.swift` (already has deleteMeeting)

- [ ] **Step 1: Add onDelete callback to MeetingCard**

In `MeetingCard.swift`, add:
```swift
var onDelete: (() -> Void)? = nil
```

Add to the context menu:
```swift
if let onDelete {
    Button(role: .destructive) {
        onDelete()
    } label: {
        Label("Delete Meeting", systemImage: "trash")
    }
}
```

- [ ] **Step 2: Add swipe-to-delete in MeetingsView**

In `MeetingsView.swift`, wrap the MeetingCard in a swipe action:

```swift
MeetingCard(
    meeting: meeting,
    onCopy: { copyBrief(for: meeting) },
    onRetry: meeting.status == .failed ? { Task { await meetingService.reprocessMeeting(meeting) } } : nil,
    onDelete: { meetingToDelete = meeting; showDeleteConfirm = true },
    onChangeClient: { newClient in meetingService.updateMeetingClient(meeting, newClient: newClient) },
    availableClients: meetingService.allClientNames
)
.swipeActions(edge: .trailing, allowsFullSwipe: false) {
    Button(role: .destructive) {
        meetingToDelete = meeting
        showDeleteConfirm = true
    } label: {
        Label("Delete", systemImage: "trash")
    }
}
```

- [ ] **Step 3: Add delete confirmation alert**

Add state variables:
```swift
@State private var meetingToDelete: Meeting?
@State private var showDeleteConfirm = false
```

Add alert:
```swift
.alert("Delete Meeting?", isPresented: $showDeleteConfirm) {
    Button("Cancel", role: .cancel) { meetingToDelete = nil }
    Button("Delete", role: .destructive) {
        if let meeting = meetingToDelete {
            meetingService.deleteMeeting(meeting)
            meetingToDelete = nil
        }
    }
} message: {
    Text("This will permanently delete \"\(meetingToDelete?.title ?? "")\" and its notes. This cannot be undone.")
}
```

- [ ] **Step 4: Build and verify**

- [ ] **Step 5: Commit**

```bash
git add MeetMind/Features/Meetings/MeetingsView.swift MeetMind/Features/Meetings/Components/MeetingCard.swift
git commit -m "feat: add swipe-to-delete and context menu delete for meetings"
```

---

### Task 4: Stop Storing Audio Files (Optional Setting)

**Files:**
- Modify: `MeetMind/Services/MeetingPipeline.swift` (delete audio after processing)
- Modify: `MeetMind/Services/MeetingService.swift` (clear audio path)
- Modify: `MeetMind/Features/Settings/SettingsView.swift` (add toggle)

- [ ] **Step 1: Add "Auto-delete audio after processing" setting**

In `SettingsView.swift`, add a toggle in the Storage section:

```swift
@AppStorage("autoDeleteAudioAfterProcessing") private var autoDeleteAudio = true

Toggle("Auto-delete audio after processing", isOn: $autoDeleteAudio)
    .font(MMTypography.body)
    .foregroundColor(MMColors.textPrimary)

Text("Audio is deleted after notes are generated. Only the transcript and notes are kept.")
    .font(MMTypography.caption1)
    .foregroundColor(MMColors.textTertiary)
```

- [ ] **Step 2: Delete audio after successful pipeline completion**

In `MeetingService.swift`, after the pipeline returns successfully (around line 409), add:

```swift
// Auto-delete audio if setting is enabled
if UserDefaults.standard.bool(forKey: "autoDeleteAudioAfterProcessing") {
    if let path = meeting.audioFilePath {
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = docsURL.appendingPathComponent(URL(fileURLWithPath: path).lastPathComponent)
        try? FileManager.default.removeItem(at: fileURL)
        meeting.audioFilePath = nil
        print("[MeetingService] Auto-deleted audio: \(fileURL.lastPathComponent)")
    }
}
```

- [ ] **Step 3: Build and verify**

- [ ] **Step 4: Commit**

```bash
git add MeetMind/Services/MeetingService.swift MeetMind/Features/Settings/SettingsView.swift
git commit -m "feat: add auto-delete audio after processing setting"
```

---

### Task 5: Rewrite Chat System — Smart Query Detection + Clean Responses

**Files:**
- Rewrite: `MeetMind/Features/Chat/MeetingChatView.swift` (the ViewModel section)
- Modify: `MeetMind/Services/GroqService.swift` (new chat method)

- [ ] **Step 1: Add smart query pre-processor to the ViewModel**

In `MeetingChatViewModel`, add query type detection:

```swift
enum QueryType {
    case stats           // "how many meetings this week"
    case actionItems     // "what action items are on me"
    case search          // "what did we discuss about X"
    case meetingLookup   // "what happened in the Meyer call"
    case taskQuery       // "how many tasks related to databricks"
    case general         // everything else
}

private func detectQueryType(_ query: String) -> QueryType {
    let q = query.lowercased()

    // Stats queries — answer directly without LLM
    if q.contains("how many meeting") || q.contains("meeting count") ||
       q.contains("meetings this week") || q.contains("meetings today") ||
       q.contains("total meetings") {
        return .stats
    }

    // Action item queries
    if q.contains("action item") || q.contains("on me") || q.contains("my tasks") ||
       q.contains("what do i need to do") || q.contains("my action") ||
       q.contains("assigned to me") {
        return .actionItems
    }

    // Task/todo queries
    if q.contains("tasks related to") || q.contains("todos about") ||
       q.contains("how many task") || q.contains("pending task") ||
       q.contains("overdue") {
        return .taskQuery
    }

    // Meeting lookup
    if q.contains("what happened in") || q.contains("summary of") ||
       q.contains("tell me about the") {
        return .meetingLookup
    }

    return q.contains("search") || q.contains("find") || q.contains("look for") ? .search : .general
}
```

- [ ] **Step 2: Add direct stat answering (no LLM needed)**

```swift
private func answerStatsDirectly(_ query: String) -> String {
    guard let meetings = meetingService?.meetings else { return "No meeting data available." }

    let calendar = Calendar.current
    let now = Date()
    let q = query.lowercased()

    let completedMeetings = meetings.filter { $0.status == .complete }

    // This week
    let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
    let thisWeek = completedMeetings.filter { $0.date >= startOfWeek }

    // Today
    let today = completedMeetings.filter { calendar.isDateInToday($0.date) }

    // Build clean response
    var response = ""

    if q.contains("this week") {
        response = "**\(thisWeek.count) meetings this week**"
        if !thisWeek.isEmpty {
            response += "\n\n"
            for m in thisWeek.sorted(by: { $0.date > $1.date }) {
                let day = DateFormatter.localizedString(from: m.date, dateStyle: .medium, timeStyle: .short)
                let client = m.clientName.map { " (\($0))" } ?? ""
                response += "- \(m.title)\(client) — \(day)\n"
            }
        }
    } else if q.contains("today") {
        response = "**\(today.count) meetings today**"
        if !today.isEmpty {
            response += "\n\n"
            for m in today {
                response += "- \(m.title)\n"
            }
        }
    } else {
        // General stats
        let allActionItems = completedMeetings.flatMap { $0.briefActionItems }
        let myItems = allActionItems.filter { $0.isMine && !$0.isCompleted }
        let clients = Set(completedMeetings.compactMap { $0.clientName })

        response = """
        **Meeting Stats**

        - **\(completedMeetings.count)** total meetings
        - **\(thisWeek.count)** this week
        - **\(today.count)** today
        - **\(clients.count)** clients
        - **\(myItems.count)** pending action items on you
        """
    }

    return response
}
```

- [ ] **Step 3: Add direct action items answering**

```swift
private func answerActionItemsDirectly(_ query: String) -> String {
    guard let meetings = meetingService?.meetings else { return "No meetings found." }

    let allItems = meetings.filter { $0.status == .complete }
        .flatMap { meeting in
            meeting.briefActionItems.map { (item: $0, meeting: meeting.title) }
        }

    let myItems = allItems.filter { $0.item.isMine && !$0.item.isCompleted }

    if myItems.isEmpty {
        return "You have **no pending action items**. All caught up!"
    }

    var response = "**\(myItems.count) action items on you:**\n\n"

    for (item, meetingTitle) in myItems {
        let due = item.dueDate.map { "due \(DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none))" } ?? "no due date"
        response += "- \(item.text) (\(due)) — from *\(meetingTitle)*\n"
    }

    return response
}
```

- [ ] **Step 4: Add task query answering**

```swift
private func answerTaskQuery(_ query: String) -> String {
    guard let todos = todoService?.todos else { return "No tasks found." }

    let q = query.lowercased()

    // Extract the topic they're asking about
    let keywords = ["related to", "about", "for", "on", "regarding"]
    var topic = ""
    for kw in keywords {
        if let range = q.range(of: kw) {
            topic = String(q[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            break
        }
    }

    if topic.isEmpty {
        // General task stats
        let pending = todos.filter { !$0.isCompleted }
        let overdue = pending.filter { $0.dueDate < Date() }
        return """
        **Task Summary**
        - **\(todos.count)** total tasks
        - **\(pending.count)** pending
        - **\(overdue.count)** overdue
        """
    }

    // Filter tasks matching the topic
    let matching = todos.filter { $0.title.lowercased().contains(topic) || ($0.clientTag?.lowercased().contains(topic) ?? false) }

    if matching.isEmpty {
        return "No tasks found related to **\(topic)**."
    }

    var response = "**\(matching.count) tasks related to \(topic):**\n\n"
    for task in matching {
        let status = task.isCompleted ? "DONE" : "PENDING"
        response += "- [\(status)] \(task.title)\n"
    }
    return response
}
```

- [ ] **Step 5: Update sendQuery to use smart routing**

```swift
func sendQuery(_ query: String) async {
    let userMessage = ChatMessage(content: query, isUser: true)
    messages.append(userMessage)

    let queryType = detectQueryType(query)

    // Direct answers — no LLM call needed, instant response
    switch queryType {
    case .stats:
        let answer = answerStatsDirectly(query)
        messages.append(ChatMessage(content: answer, isUser: false))
        return
    case .actionItems:
        let answer = answerActionItemsDirectly(query)
        messages.append(ChatMessage(content: answer, isUser: false))
        return
    case .taskQuery:
        let answer = answerTaskQuery(query)
        messages.append(ChatMessage(content: answer, isUser: false))
        return
    default:
        break
    }

    // LLM-powered answers for search/analysis queries
    isLoading = true
    do {
        let context = buildMeetingContext(for: query)
        let response = try await GroqService.shared.chatAboutMeetings(
            query: query,
            meetingContext: context.text
        )
        messages.append(ChatMessage(content: response, isUser: false, sourceMeetings: context.meetingTitles))
    } catch {
        messages.append(ChatMessage(content: "Sorry: \(error.localizedDescription)", isUser: false))
    }
    isLoading = false
}
```

- [ ] **Step 6: Improve the chat system prompt for cleaner responses**

In `GroqService.swift`, update the `chatAboutMeetings` system prompt:

```swift
let systemPrompt = """
You are MeetMind, a meeting intelligence assistant. Answer based ONLY on the meeting context provided.

Rules:
- Be direct and concise. Lead with the answer, not preamble.
- Use **bold** for names, dates, and key terms.
- Use bullet points for lists — never long paragraphs.
- If listing items, use a clean formatted list.
- If the answer involves numbers, put the number first and bold it.
- If the answer isn't in the context, say "I don't have information about that in your meetings."
- When referencing a meeting, mention its title in *italics*.
- Keep responses under 200 words unless the user asks for detail.
"""
```

- [ ] **Step 7: Update suggestion chips to be more useful**

In `MeetingChatView.swift`, update `suggestionChips`:

```swift
private var suggestionChips: [String] {
    [
        "How many meetings this week?",
        "What action items are on me?",
        "What were the key decisions?",
        "Tasks related to Databricks",
        "What did the customer ask for?",
        "Summarize yesterday's meetings",
        "Show overdue items",
        "What's my busiest client?"
    ]
}
```

- [ ] **Step 8: Add markdown rendering to chat bubbles**

In `MessageBubble`, replace plain `Text(message.content)` with a markdown-aware renderer that handles **bold** and bullet points (similar to the `renderBoldText` in MeetingDetailView).

- [ ] **Step 9: Build and verify**

- [ ] **Step 10: Commit**

```bash
git add MeetMind/Features/Chat/MeetingChatView.swift MeetMind/Services/GroqService.swift
git commit -m "feat: rewrite chat with smart query routing, instant stats, and cleaner responses"
```

---

### Task 6: Improve Meeting-Specific Chat (MeetingChatSheet)

**Files:**
- Modify: `MeetMind/Features/Meetings/MeetingChatSheet.swift`

- [ ] **Step 1: Improve context building — include full brief, not truncated**

Replace the context builder in `sendMessage()`:

```swift
var context = "Meeting: \(meeting.title)\n"
context += "Date: \(meeting.date.formatted())\n"
if let client = meeting.clientName { context += "Client: \(client)\n" }
if let summary = meeting.briefSummary {
    context += "\nFull Meeting Notes:\n\(summary)\n"
}
if !meeting.briefDecisions.isEmpty {
    context += "\nDecisions:\n" + meeting.briefDecisions.map { "- \($0)" }.joined(separator: "\n") + "\n"
}
if !meeting.briefActionItems.isEmpty {
    context += "\nAction Items:\n" + meeting.briefActionItems.map {
        "- \($0.text) (owner: \($0.owner), mine: \($0.isMine), due: \($0.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "not set"), completed: \($0.isCompleted))"
    }.joined(separator: "\n") + "\n"
}
if !meeting.briefKeyQuotes.isEmpty {
    context += "\nKey Quotes:\n" + meeting.briefKeyQuotes.map { "- \($0)" }.joined(separator: "\n") + "\n"
}
if let transcript = meeting.rawTranscript {
    // Include more transcript — up to 6000 chars
    context += "\nTranscript:\n\(String(transcript.prefix(6000)))\n"
}
```

- [ ] **Step 2: Add better suggestions for meeting-specific chat**

```swift
private let suggestions = [
    "What action items are on me from this call?",
    "What did the customer ask for?",
    "Summarize the key decisions",
    "What are the open questions?",
    "What risks were discussed?",
    "Draft a follow-up message",
    "What were the blockers mentioned?",
    "Who committed to what?"
]
```

- [ ] **Step 3: Build and verify**

- [ ] **Step 4: Commit**

```bash
git add MeetMind/Features/Meetings/MeetingChatSheet.swift
git commit -m "feat: improve meeting-specific chat with full context and better suggestions"
```

---

### Task 7: Update Sample Meetings to New Format

**Files:**
- Modify: `MeetMind/Services/MeetingService.swift` (seedSampleMeetings)

- [ ] **Step 1: Update sample meeting summaries to Golden Template format**

Update the `briefSummary` of the first sample meeting to use the new format:

```swift
briefSummary: """
# Strategic Planning for Meyer Account: POC Readout and Transformation Roadmap

**Attendees:** **Mitchell** (Databricks), **Gaurav** (Celebal)
**Type:** Sales Call

---

## TL;DR
**Maju** wants to expand the Celebal team with 6 more engineers. The Metrics View POC is progressing well but blocked on table access. The team agreed on a hybrid approach — keep UI filters in Power BI while migrating core transformations to Databricks. Final POC readout targeted for week of **March 26th**.

## Key Decisions
- **Adopt hybrid POC approach** — keep presentation-layer logic in Power BI, core metrics in Databricks. Decided by **Mitchell** and **Gaurav**.
- **Use self-service workspace for testing** — bypass production deployment bottleneck. Decided by **Gaurav**.
- **Target POC readout for March 26th** — pending resolution of table access blocker.

## Action Items
| Task | Owner | Due | Priority |
|------|-------|-----|----------|
| Create summary presentation for David | **Gaurav** | Tomorrow | High |
| Talk to Pankaj about self-service workspace | **Gaurav** | This week | High |
| Send self-service workspace role name | **Mitchell** | This week | Medium |
| Follow up on remaining table access | **Gaurav** | ASAP | High |
| Schedule whiteboarding session | **Mitchell** | Next week | Medium |

## Open Questions
- What is the full scope of Teradata migration without profile analyzer data?
- How will COBOL mainframe applications be handled in the migration?
""",
```

- [ ] **Step 2: Update remaining sample meetings similarly**

Apply the same Golden Template format to the other 4 sample meetings.

- [ ] **Step 3: Build and verify**

- [ ] **Step 4: Commit**

```bash
git add MeetMind/Services/MeetingService.swift
git commit -m "feat: update sample meetings to Golden Template format"
```

---

### Task 8: Final Polish — Build, Test, Verify

- [ ] **Step 1: Full build**

```bash
cd /Users/modi/R&D/MeetMind && xcodebuild -scheme MeetMind -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

- [ ] **Step 2: Test on simulator**

- Verify meeting detail view shows TL;DR card prominently
- Verify decisions and action items are cleanly formatted
- Verify swipe-to-delete works on meeting cards
- Test chat: "How many meetings this week?" → instant, formatted answer
- Test chat: "What action items are on me?" → instant list
- Test chat: "Tasks related to Databricks" → instant filtered list
- Test chat: "What did the customer ask for?" → LLM-powered answer with sources

- [ ] **Step 3: Install on device**

```bash
xcodebuild -scheme MeetMind -destination 'generic/platform=iOS' -allowProvisioningUpdates build
```

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: complete meeting notes enhancement — Golden Template, smart chat, swipe-to-delete"
```
