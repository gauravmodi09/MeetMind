# MeetMind macOS Desktop App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the MeetMind macOS app with a three-panel power-user layout (icon rail + list + detail), Speakly-inspired clean theme, full feature parity with iOS, and menu bar companion.

**Architecture:** All macOS files live inside `MeetMind/MacApp/` wrapped in `#if os(macOS)`. They share the same Xcode target as the iOS app — no separate Mac target. Views are built with SwiftUI using `NavigationSplitView` alternatives and custom layouts. All existing services (`MeetingService`, `TodoService`, `AudioRecordingService`, `SystemAudioCapture`, `MeetingAppDetector`) are reused unchanged.

**Tech Stack:** SwiftUI (macOS 14+), AVFoundation, ScreenCaptureKit, existing MeetMind services

---

## File Structure

```
MeetMind/MacApp/
├── MeetMindMacApp.swift              — MODIFY: add WatchConnectivity activation, environment objects
├── MacMainView.swift                 — REWRITE: three-panel layout with icon rail
├── MenuBarView.swift                 — REWRITE: new Speakly-style design with dual record buttons
├── Views/
│   ├── MacIconRail.swift             — CREATE: dark icon rail navigation component
│   ├── MacListPanel.swift            — CREATE: list panel that switches content by active section
│   ├── MacMeetingListPanel.swift     — CREATE: meetings list with date grouping and search
│   ├── MacMeetingDetail.swift        — CREATE: tabbed meeting detail (summary/transcript/actions/notes/chat)
│   ├── MacRecordingView.swift        — CREATE: recording UI with system audio/mic toggle
│   ├── MacTodosView.swift            — CREATE: todos list + detail panel
│   ├── MacNotesView.swift            — CREATE: notes list + detail panel
│   ├── MacLibraryView.swift          — CREATE: library/analytics view
│   ├── MacChatView.swift             — CREATE: AI chat view
│   └── MacSettingsView.swift         — CREATE: settings view (full-width, no list panel)
├── MeetingAppDetector.swift          — KEEP AS-IS
└── SystemAudioCapture.swift          — KEEP AS-IS
```

All new files must be added to the Xcode project's `project.pbxproj` (PBXFileReference + PBXBuildFile + PBXGroup) and wrapped in `#if os(macOS) ... #endif`.

---

### Task 1: Icon Rail Navigation Component

**Files:**
- Create: `MeetMind/MacApp/Views/MacIconRail.swift`

- [ ] **Step 1: Create the Views directory**

```bash
mkdir -p /Users/modi/R\&D/MeetMind/MeetMind/MacApp/Views
```

- [ ] **Step 2: Write MacIconRail.swift**

```swift
#if os(macOS)
import SwiftUI

enum MacSection: String, CaseIterable, Identifiable {
    case meetings
    case todos
    case notes
    case library
    case chat
    case settings

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .meetings: return "waveform.circle.fill"
        case .todos:    return "checkmark.circle.fill"
        case .notes:    return "note.text"
        case .library:  return "books.vertical.fill"
        case .chat:     return "bubble.left.and.bubble.right.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var label: String {
        switch self {
        case .meetings: return "Meetings"
        case .todos:    return "Todos"
        case .notes:    return "Notes"
        case .library:  return "Library"
        case .chat:     return "Chat"
        case .settings: return "Settings"
        }
    }
}

struct MacIconRail: View {
    @Binding var activeSection: MacSection
    var isRecording: Bool = false

    private let railWidth: CGFloat = 56
    private let railBackground = Color(red: 0.102, green: 0.102, blue: 0.180) // #1a1a2e

    var body: some View {
        VStack(spacing: 6) {
            // App icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isRecording ? Color.red : MMColors.primary)
                    .frame(width: 32, height: 32)
                Image(systemName: isRecording ? "stop.fill" : "waveform.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 12)

            // Main nav items (exclude settings)
            ForEach(MacSection.allCases.filter { $0 != .settings }) { section in
                railButton(for: section)
            }

            Spacer()

            // Settings pinned to bottom
            railButton(for: .settings)
        }
        .padding(.vertical, 16)
        .frame(width: railWidth)
        .background(railBackground)
    }

    private func railButton(for section: MacSection) -> some View {
        Button {
            activeSection = section
        } label: {
            VStack(spacing: 2) {
                Image(systemName: section.icon)
                    .font(.system(size: 14))
                Text(section.label)
                    .font(.system(size: 8))
            }
            .frame(width: 36, height: 36)
            .foregroundColor(activeSection == section ? .white : .white.opacity(0.4))
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(activeSection == section
                          ? MMColors.primary.opacity(0.25)
                          : Color.white.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }
}
#endif
```

- [ ] **Step 3: Verify it compiles**

```bash
cd /Users/modi/R\&D/MeetMind && xcodebuild -scheme "MeetMind" -destination "platform=macOS" build 2>&1 | grep -E "error:|BUILD"
```

Note: This file must be added to the pbxproj. Each task that creates a file must add it. Use python script or manual edit to add PBXFileReference, PBXBuildFile, and PBXGroup entry.

- [ ] **Step 4: Commit**

```bash
git add MeetMind/MacApp/Views/MacIconRail.swift
git commit -m "feat(mac): add icon rail navigation component"
```

---

### Task 2: Meeting List Panel

**Files:**
- Create: `MeetMind/MacApp/Views/MacMeetingListPanel.swift`

- [ ] **Step 1: Write MacMeetingListPanel.swift**

```swift
#if os(macOS)
import SwiftUI

struct MacMeetingListPanel: View {
    @EnvironmentObject var meetingService: MeetingService
    @Binding var selectedMeetingId: UUID?
    @State private var searchText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Meetings")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.180))
                Spacer()
                Button {
                    // Start new recording — handled by parent
                    NotificationCenter.default.post(name: .macStartRecording, object: nil)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(RoundedRectangle(cornerRadius: 6).fill(MMColors.primary))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                TextField("Search meetings...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.88)))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 14)

            // Meeting list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(groupedMeetings, id: \.key) { group in
                        // Date header
                        Text(group.key)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 6)

                        ForEach(group.meetings) { meeting in
                            meetingRow(meeting)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 6)
                        }
                    }
                }
            }
        }
        .frame(width: 240)
        .background(Color(red: 0.973, green: 0.973, blue: 0.980)) // #f8f8fa
    }

    private func meetingRow(_ meeting: Meeting) -> some View {
        Button {
            selectedMeetingId = meeting.id
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(meeting.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.180))
                        .lineLimit(1)
                    Spacer()
                    if meeting.status == .complete {
                        Circle()
                            .fill(Color(red: 0.063, green: 0.725, blue: 0.506)) // #10B981
                            .frame(width: 6, height: 6)
                    } else if meeting.status == .processing {
                        Circle()
                            .fill(Color(red: 0.961, green: 0.620, blue: 0.043)) // #F59E0B
                            .frame(width: 6, height: 6)
                    }
                }
                Text("\(meeting.date.formatted(date: .omitted, time: .shortened)) · \(formatDuration(meeting.duration))\(meeting.briefActionItems.isEmpty ? "" : " · \(meeting.briefActionItems.count) actions")")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(11)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectedMeetingId == meeting.id ? MMColors.primary : Color(white: 0.93), lineWidth: selectedMeetingId == meeting.id ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Grouping

    private struct MeetingGroup: Identifiable {
        let key: String
        let meetings: [Meeting]
        var id: String { key }
    }

    private var filteredMeetings: [Meeting] {
        if searchText.isEmpty { return meetingService.meetings }
        return meetingService.meetings.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.clientName ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedMeetings: [MeetingGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredMeetings) { meeting -> String in
            if calendar.isDateInToday(meeting.date) { return "Today" }
            if calendar.isDateInYesterday(meeting.date) { return "Yesterday" }
            if calendar.isDate(meeting.date, equalTo: Date(), toGranularity: .weekOfYear) { return "This Week" }
            return meeting.date.formatted(date: .abbreviated, time: .omitted)
        }
        // Sort groups: Today first, then Yesterday, then by date descending
        let order = ["Today", "Yesterday", "This Week"]
        return grouped.map { MeetingGroup(key: $0.key, meetings: $0.value.sorted { $0.date > $1.date }) }
            .sorted { a, b in
                let ai = order.firstIndex(of: a.key) ?? Int.max
                let bi = order.firstIndex(of: b.key) ?? Int.max
                if ai != bi { return ai < bi }
                return a.key > b.key
            }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}

extension Notification.Name {
    static let macStartRecording = Notification.Name("macStartRecording")
}
#endif
```

- [ ] **Step 2: Add to pbxproj, verify compile**

```bash
cd /Users/modi/R\&D/MeetMind && xcodebuild -scheme "MeetMind" -destination "platform=macOS" build 2>&1 | grep -E "error:|BUILD"
```

- [ ] **Step 3: Commit**

```bash
git add MeetMind/MacApp/Views/MacMeetingListPanel.swift
git commit -m "feat(mac): add meeting list panel with search and date grouping"
```

---

### Task 3: Meeting Detail View with Tabs

**Files:**
- Create: `MeetMind/MacApp/Views/MacMeetingDetail.swift`

- [ ] **Step 1: Write MacMeetingDetail.swift**

```swift
#if os(macOS)
import SwiftUI

struct MacMeetingDetail: View {
    let meeting: Meeting
    @State private var activeTab: DetailTab = .summary

    enum DetailTab: String, CaseIterable {
        case summary = "Summary"
        case transcript = "Transcript"
        case actions = "Action Items"
        case notes = "Notes"
        case chat = "AI Chat"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meeting.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.180))

                    HStack(spacing: 8) {
                        Text(meeting.date.formatted(date: .abbreviated, time: .shortened))
                        Text("·")
                        Text(formatDuration(meeting.duration))
                        if let client = meeting.clientName {
                            Text("·")
                            Text(client)
                        }
                        Text("·")
                        Text(meeting.status.displayName)
                            .foregroundColor(statusColor)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    macActionButton("Export", icon: "square.and.arrow.up")
                    macActionButton("Share", icon: "paperplane")
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            // Tab bar
            HStack(spacing: 0) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Button {
                        activeTab = tab
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: activeTab == tab ? .semibold : .regular))
                            .foregroundColor(activeTab == tab ? MMColors.primary : .secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .overlay(alignment: .bottom) {
                                if activeTab == tab {
                                    Rectangle()
                                        .fill(MMColors.primary)
                                        .frame(height: 2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .overlay(alignment: .bottom) {
                Divider()
            }
            .padding(.horizontal, 24)

            // Tab content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch activeTab {
                    case .summary:
                        summaryTab
                    case .transcript:
                        transcriptTab
                    case .actions:
                        actionsTab
                    case .notes:
                        notesTab
                    case .chat:
                        chatTab
                    }
                }
                .padding(24)
            }
        }
        .background(Color.white)
    }

    // MARK: - Summary Tab

    private var summaryTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let summary = meeting.briefSummary {
                detailSection("Key Points") {
                    Text(summary)
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.267, green: 0.267, blue: 0.267))
                        .lineSpacing(4)
                        .textSelection(.enabled)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 0.98, green: 0.98, blue: 0.98)))
                }
            }

            if !meeting.briefDecisions.isEmpty {
                detailSection("Decisions") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(meeting.briefDecisions, id: \.self) { decision in
                            HStack(alignment: .top, spacing: 8) {
                                Text("→")
                                    .foregroundColor(MMColors.primary)
                                    .font(.system(size: 14))
                                Text(decision)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(red: 0.267, green: 0.267, blue: 0.267))
                            }
                        }
                    }
                }
            }

            if !meeting.briefActionItems.isEmpty {
                detailSection("Action Items (\(meeting.briefActionItems.count))") {
                    VStack(spacing: 6) {
                        ForEach(meeting.briefActionItems) { item in
                            actionItemRow(item)
                        }
                    }
                }
            }

            if !meeting.briefKeyTopics.isEmpty {
                detailSection("Key Topics") {
                    FlowLayout(spacing: 6) {
                        ForEach(meeting.briefKeyTopics, id: \.self) { topic in
                            Text(topic)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(MMColors.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(MMColors.primary.opacity(0.1))
                                )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Transcript Tab

    private var transcriptTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let transcript = meeting.rawTranscript, !transcript.isEmpty {
                Text(transcript)
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.267, green: 0.267, blue: 0.267))
                    .lineSpacing(4)
                    .textSelection(.enabled)
            } else {
                emptyState(icon: "text.alignleft", message: "No transcript available")
            }
        }
    }

    // MARK: - Actions Tab

    private var actionsTab: some View {
        VStack(alignment: .leading, spacing: 6) {
            if meeting.briefActionItems.isEmpty {
                emptyState(icon: "checkmark.circle", message: "No action items")
            } else {
                ForEach(meeting.briefActionItems) { item in
                    actionItemRow(item)
                }
            }
        }
    }

    // MARK: - Notes Tab

    private var notesTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let notes = meeting.userNotes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 13))
                    .lineSpacing(4)
                    .textSelection(.enabled)
            } else if let notepad = meeting.notepadContent, !notepad.isEmpty {
                Text(notepad)
                    .font(.system(size: 13))
                    .lineSpacing(4)
                    .textSelection(.enabled)
            } else {
                emptyState(icon: "note.text", message: "No notes for this meeting")
            }
        }
    }

    // MARK: - Chat Tab

    private var chatTab: some View {
        VStack {
            emptyState(icon: "bubble.left.and.bubble.right", message: "AI Chat — coming soon on macOS")
        }
    }

    // MARK: - Components

    private func detailSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.180))
            content()
        }
    }

    private func actionItemRow(_ item: ActionItem) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundColor(item.isCompleted ? Color(red: 0.063, green: 0.725, blue: 0.506) : Color(white: 0.8))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.text)
                    .font(.system(size: 12))
                    .foregroundColor(item.isCompleted ? .secondary : Color(red: 0.2, green: 0.2, blue: 0.2))
                    .strikethrough(item.isCompleted)

                HStack(spacing: 4) {
                    if !item.owner.isEmpty {
                        Text(item.owner)
                    }
                    if let due = item.dueDate {
                        Text("· Due \(due.formatted(date: .abbreviated, time: .omitted))")
                    }
                }
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.98, green: 0.98, blue: 0.98)))
    }

    private func macActionButton(_ title: String, icon: String) -> some View {
        Button {} label: {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10))
                Text(title).font(.system(size: 11))
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(red: 0.94, green: 0.94, blue: 0.96)))
        }
        .buttonStyle(.plain)
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var statusColor: Color {
        switch meeting.status {
        case .complete:   return Color(red: 0.063, green: 0.725, blue: 0.506)
        case .processing: return Color(red: 0.961, green: 0.620, blue: 0.043)
        case .recording:  return .red
        case .failed:     return .red
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
#endif
```

- [ ] **Step 2: Add to pbxproj, verify compile**

- [ ] **Step 3: Commit**

```bash
git add MeetMind/MacApp/Views/MacMeetingDetail.swift
git commit -m "feat(mac): add tabbed meeting detail view"
```

---

### Task 4: Recording View with Audio Source Toggle

**Files:**
- Create: `MeetMind/MacApp/Views/MacRecordingView.swift`

- [ ] **Step 1: Write MacRecordingView.swift**

```swift
#if os(macOS)
import SwiftUI

enum AudioSource: String, CaseIterable {
    case system = "System Audio"
    case microphone = "Microphone"

    var icon: String {
        switch self {
        case .system: return "display"
        case .microphone: return "mic.fill"
        }
    }
}

struct MacRecordingView: View {
    @EnvironmentObject var meetingService: MeetingService
    @StateObject private var systemCapture = SystemAudioCapture()
    @ObservedObject var appDetector: MeetingAppDetector
    @Binding var isRecording: Bool

    @State private var audioSource: AudioSource = .system
    @State private var duration: TimeInterval = 0
    @State private var meetingTitle = "New Meeting"
    @State private var timer: Timer?
    @State private var audioFileURL: URL?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Stop button
            Button {
                stopRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 56, height: 56)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                }
            }
            .buttonStyle(.plain)

            // Timer
            Text(formatTime(duration))
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.180))

            // Status
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text("Recording — \(meetingTitle)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.red)
            }

            // Audio source selector
            VStack(spacing: 8) {
                Text("AUDIO SOURCE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)

                HStack(spacing: 8) {
                    ForEach(AudioSource.allCases, id: \.self) { source in
                        Button {
                            // Can't switch during recording — show as selected indicator only
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: source.icon)
                                    .font(.system(size: 12))
                                Text(source.rawValue)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(audioSource == source ? .white : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(audioSource == source ? MMColors.primary : Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(audioSource == source ? Color.clear : Color(white: 0.9))
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let app = appDetector.activeMeetingApp {
                    Text("Capturing: \(app.displayName)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(red: 0.973, green: 0.973, blue: 0.980)))

            // Waveform
            HStack(spacing: 2) {
                ForEach(0..<15, id: \.self) { i in
                    let level = audioSource == .system ? systemCapture.audioLevel : AudioRecordingService.shared.audioLevel
                    let height = max(4, CGFloat(level) * 40 + CGFloat.random(in: 0...8))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(MMColors.primary)
                        .frame(width: 3, height: height)
                        .animation(.easeInOut(duration: 0.15), value: level)
                }
            }
            .frame(height: 40)

            // Controls
            HStack(spacing: 12) {
                Button("⏸ Pause") {
                    // Future: pause support
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.94, green: 0.94, blue: 0.96)))
                .buttonStyle(.plain)

                Button("⏹ Stop & Process") {
                    stopRecording()
                }
                .foregroundColor(.white)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.red))
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .onAppear {
            startRecording()
        }
    }

    // MARK: - Recording Control

    private func startRecording() {
        // Determine audio source based on meeting app detection
        if appDetector.isInMeeting {
            audioSource = .system
        } else {
            audioSource = .microphone
        }

        Task {
            do {
                if audioSource == .system {
                    try await systemCapture.startCapture()
                } else {
                    audioFileURL = try AudioRecordingService.shared.startRecording()
                }
                startTimer()
            } catch {
                print("[MacRecording] Failed to start: \(error)")
                isRecording = false
            }
        }
    }

    private func stopRecording() {
        stopTimer()

        Task {
            var fileURL: URL?
            if audioSource == .system {
                fileURL = await systemCapture.stopCapture()
            } else {
                fileURL = AudioRecordingService.shared.stopRecording()
            }

            isRecording = false

            // Process through pipeline if we have audio
            if let url = fileURL {
                await meetingService.processRecordedAudio(url: url, title: meetingTitle)
            }
        }
    }

    private func startTimer() {
        duration = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            duration += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 { return String(format: "%02d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}
#endif
```

- [ ] **Step 2: Add to pbxproj, verify compile**

- [ ] **Step 3: Commit**

```bash
git add MeetMind/MacApp/Views/MacRecordingView.swift
git commit -m "feat(mac): add recording view with system audio/mic toggle"
```

---

### Task 5: Todos, Notes, Library, Chat, Settings Views

**Files:**
- Create: `MeetMind/MacApp/Views/MacTodosView.swift`
- Create: `MeetMind/MacApp/Views/MacNotesView.swift`
- Create: `MeetMind/MacApp/Views/MacLibraryView.swift`
- Create: `MeetMind/MacApp/Views/MacChatView.swift`
- Create: `MeetMind/MacApp/Views/MacSettingsView.swift`

- [ ] **Step 1: Write MacTodosView.swift**

```swift
#if os(macOS)
import SwiftUI

struct MacTodosView: View {
    @EnvironmentObject var todoService: TodoService
    @State private var filter: TodoFilter = .pending

    enum TodoFilter: String, CaseIterable {
        case pending = "Pending"
        case completed = "Completed"
        case all = "All"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Todos")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Picker("", selection: $filter) {
                    ForEach(TodoFilter.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding(24)

            Divider()

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(filteredTodos) { todo in
                        HStack(spacing: 10) {
                            Button {
                                todoService.toggleCompletion(for: todo.id)
                            } label: {
                                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(todo.isCompleted ? Color(red: 0.063, green: 0.725, blue: 0.506) : Color(white: 0.8))
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(todo.title)
                                    .font(.system(size: 13))
                                    .strikethrough(todo.isCompleted)
                                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                                HStack(spacing: 8) {
                                    Text(todo.dueDate.formatted(date: .abbreviated, time: .omitted))
                                    if let client = todo.clientTag {
                                        Text("· \(client)")
                                    }
                                    Text("· \(todo.priority.rawValue.capitalized)")
                                        .foregroundColor(priorityColor(todo.priority))
                                }
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.98, green: 0.98, blue: 0.98)))
                    }
                }
                .padding(24)
            }
        }
        .background(Color.white)
    }

    private var filteredTodos: [TodoItem] {
        switch filter {
        case .pending:   return todoService.todos.filter { !$0.isCompleted }
        case .completed: return todoService.todos.filter { $0.isCompleted }
        case .all:       return todoService.todos
        }
    }

    private func priorityColor(_ priority: TodoPriority) -> Color {
        switch priority {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .secondary
        }
    }
}
#endif
```

- [ ] **Step 2: Write MacNotesView.swift**

```swift
#if os(macOS)
import SwiftUI

struct MacNotesView: View {
    @EnvironmentObject var meetingService: MeetingService

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Notes")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
            }
            .padding(24)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(meetingsWithNotes) { meeting in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(meeting.title)
                                .font(.system(size: 14, weight: .semibold))
                            Text(meeting.userNotes ?? meeting.notepadContent ?? "")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                            Text(meeting.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 10))
                                .foregroundColor(.tertiary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 0.98, green: 0.98, blue: 0.98)))
                    }
                }
                .padding(24)
            }
        }
        .background(Color.white)
    }

    private var meetingsWithNotes: [Meeting] {
        meetingService.meetings.filter { meeting in
            (meeting.userNotes != nil && !meeting.userNotes!.isEmpty) ||
            (meeting.notepadContent != nil && !meeting.notepadContent!.isEmpty)
        }
    }
}
#endif
```

- [ ] **Step 3: Write MacLibraryView.swift**

```swift
#if os(macOS)
import SwiftUI

struct MacLibraryView: View {
    @EnvironmentObject var meetingService: MeetingService

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Library")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
            }
            .padding(24)

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Stats cards
                    HStack(spacing: 12) {
                        statCard(value: "\(meetingService.meetings.count)", label: "Total Meetings", color: MMColors.primary)
                        statCard(value: "\(totalActionItems)", label: "Action Items", color: Color(red: 0.063, green: 0.725, blue: 0.506))
                        statCard(value: formattedTotalTime, label: "Time Recorded", color: Color(red: 0.231, green: 0.510, blue: 0.965))
                    }

                    // By template
                    VStack(alignment: .leading, spacing: 8) {
                        Text("By Meeting Type")
                            .font(.system(size: 14, weight: .semibold))
                        ForEach(templateCounts, id: \.template) { item in
                            HStack {
                                Text(item.template.displayName)
                                    .font(.system(size: 13))
                                Spacer()
                                Text("\(item.count)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(MMColors.primary)
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.98, green: 0.98, blue: 0.98)))
                        }
                    }
                }
                .padding(24)
            }
        }
        .background(Color.white)
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(color: .black.opacity(0.05), radius: 4, y: 2))
    }

    private var totalActionItems: Int {
        meetingService.meetings.reduce(0) { $0 + $1.briefActionItems.count }
    }

    private var formattedTotalTime: String {
        let totalMinutes = Int(meetingService.meetings.reduce(0) { $0 + $1.duration }) / 60
        if totalMinutes < 60 { return "\(totalMinutes)m" }
        return "\(totalMinutes / 60)h \(totalMinutes % 60)m"
    }

    private struct TemplateCount: Identifiable {
        let template: MeetingTemplate
        let count: Int
        var id: String { template.rawValue }
    }

    private var templateCounts: [TemplateCount] {
        let grouped = Dictionary(grouping: meetingService.meetings, by: \.template)
        return grouped.map { TemplateCount(template: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
}
#endif
```

- [ ] **Step 4: Write MacChatView.swift**

```swift
#if os(macOS)
import SwiftUI

struct MacChatView: View {
    @EnvironmentObject var meetingService: MeetingService
    @State private var messageText = ""
    @State private var messages: [(String, Bool)] = [] // (text, isUser)

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("AI Chat")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
            }
            .padding(24)

            Divider()

            // Messages
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { _, msg in
                        HStack {
                            if msg.1 { Spacer() }
                            Text(msg.0)
                                .font(.system(size: 13))
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(msg.1 ? MMColors.primary : Color(red: 0.95, green: 0.95, blue: 0.97))
                                )
                                .foregroundColor(msg.1 ? .white : .primary)
                            if !msg.1 { Spacer() }
                        }
                    }
                }
                .padding(24)
            }

            Divider()

            // Input
            HStack(spacing: 8) {
                TextField("Ask about your meetings...", text: $messageText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit { sendMessage() }

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(messageText.isEmpty ? .secondary : MMColors.primary)
                }
                .buttonStyle(.plain)
                .disabled(messageText.isEmpty)
            }
            .padding(16)
        }
        .background(Color.white)
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        let text = messageText
        messages.append((text, true))
        messageText = ""
        // AI response placeholder — integrate with GroqService later
        messages.append(("I'll analyze your meetings and get back to you. (AI integration pending)", false))
    }
}
#endif
```

- [ ] **Step 5: Write MacSettingsView.swift**

```swift
#if os(macOS)
import SwiftUI

struct MacSettingsView: View {
    @AppStorage("groqAPIKey") private var apiKey = ""
    @AppStorage("defaultAudioSource") private var defaultAudioSource = "system"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Settings")
                    .font(.system(size: 20, weight: .bold))

                // AI & Processing
                settingsSection("AI & Processing") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Groq API Key")
                            .font(.system(size: 12, weight: .medium))
                        SecureField("Enter your Groq API key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                    }
                }

                // Recording
                settingsSection("Recording") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default Audio Source")
                            .font(.system(size: 12, weight: .medium))
                        Picker("", selection: $defaultAudioSource) {
                            Text("System Audio").tag("system")
                            Text("Microphone").tag("microphone")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 240)

                        Text("System Audio captures meeting apps (Zoom, Teams, etc). Microphone uses your Mac's built-in mic.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                // About
                settingsSection("About") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MeetMind for Mac")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Version 1.0")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(24)
        }
        .background(Color.white)
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.180))
            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 0.98, green: 0.98, blue: 0.98)))
        }
    }
}
#endif
```

- [ ] **Step 6: Add all 5 files to pbxproj, verify compile**

- [ ] **Step 7: Commit**

```bash
git add MeetMind/MacApp/Views/
git commit -m "feat(mac): add todos, notes, library, chat, and settings views"
```

---

### Task 6: Rewrite MacMainView — Three-Panel Layout

**Files:**
- Modify: `MeetMind/MacApp/MacMainView.swift`

- [ ] **Step 1: Rewrite MacMainView.swift**

```swift
#if os(macOS)
import SwiftUI

struct MacMainView: View {
    @EnvironmentObject var meetingService: MeetingService
    @StateObject private var todoService = TodoService.shared
    @StateObject private var appDetector = MeetingAppDetector.shared

    @State private var activeSection: MacSection = .meetings
    @State private var selectedMeetingId: UUID?
    @State private var isRecording = false

    var body: some View {
        HStack(spacing: 0) {
            // Icon Rail
            MacIconRail(activeSection: $activeSection, isRecording: isRecording)

            // Content area
            if isRecording {
                MacRecordingView(
                    appDetector: appDetector,
                    isRecording: $isRecording
                )
                .environmentObject(meetingService)
            } else {
                switch activeSection {
                case .meetings:
                    meetingsLayout
                case .todos:
                    MacTodosView()
                        .environmentObject(todoService)
                case .notes:
                    MacNotesView()
                        .environmentObject(meetingService)
                case .library:
                    MacLibraryView()
                        .environmentObject(meetingService)
                case .chat:
                    MacChatView()
                        .environmentObject(meetingService)
                case .settings:
                    MacSettingsView()
                }
            }
        }
        .frame(minWidth: 700, minHeight: 450)
        .onAppear {
            appDetector.startMonitoring()
        }
        .onDisappear {
            appDetector.stopMonitoring()
        }
        .onReceive(NotificationCenter.default.publisher(for: .macStartRecording)) { _ in
            isRecording = true
        }
    }

    // MARK: - Meetings: List + Detail

    private var meetingsLayout: some View {
        HStack(spacing: 0) {
            MacMeetingListPanel(selectedMeetingId: $selectedMeetingId)
                .environmentObject(meetingService)

            Divider()

            if let meetingId = selectedMeetingId,
               let meeting = meetingService.meetings.first(where: { $0.id == meetingId }) {
                MacMeetingDetail(meeting: meeting)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "waveform.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("Select a meeting")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            }
        }
    }
}
#endif
```

- [ ] **Step 2: Verify compile**

```bash
cd /Users/modi/R\&D/MeetMind && xcodebuild -scheme "MeetMind" -destination "platform=macOS" build 2>&1 | grep -E "error:|BUILD"
```

- [ ] **Step 3: Commit**

```bash
git add MeetMind/MacApp/MacMainView.swift
git commit -m "feat(mac): rewrite main view with three-panel layout"
```

---

### Task 7: Rewrite MenuBarView

**Files:**
- Modify: `MeetMind/MacApp/MenuBarView.swift`

- [ ] **Step 1: Rewrite MenuBarView.swift**

```swift
#if os(macOS)
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var meetingService: MeetingService
    @StateObject private var systemCapture = SystemAudioCapture()
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var audioFileURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("MeetMind")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(isRecording ? "Recording..." : "Ready to record")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                LinearGradient(colors: [MMColors.primary, Color(red: 0.659, green: 0.333, blue: 0.969)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )

            if isRecording {
                // Recording state
                VStack(spacing: 10) {
                    Text(formatTime(recordingDuration))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                    Button {
                        stopMenuBarRecording()
                    } label: {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("Stop Recording")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.large)
                }
                .padding(12)
            } else {
                // Quick actions
                HStack(spacing: 8) {
                    Button {
                        startMicRecording()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "mic.fill").font(.system(size: 11))
                            Text("Record Mic").font(.system(size: 11, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(MMColors.primary)
                    .controlSize(.regular)

                    Button {
                        startSystemRecording()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "display").font(.system(size: 11))
                            Text("System").font(.system(size: 11, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.102, green: 0.102, blue: 0.180))
                    .controlSize(.regular)
                }
                .padding(12)
            }

            Divider()

            // Recent meetings
            if !meetingService.meetings.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("RECENT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                        .padding(.horizontal, 14)
                        .padding(.top, 10)
                        .padding(.bottom, 6)

                    ForEach(meetingService.meetings.prefix(3)) { meeting in
                        HStack {
                            Text(meeting.title)
                                .font(.system(size: 12))
                                .lineLimit(1)
                            Spacer()
                            Text(meeting.date, style: .relative)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                    }
                }
                .padding(.bottom, 6)
            }

            Divider()

            // Footer
            HStack {
                Button("Open MeetMind") {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { !($0 is NSPanel) }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(MMColors.primary)
                .buttonStyle(.plain)

                Spacer()

                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .frame(width: 280)
    }

    // MARK: - Recording

    private func startMicRecording() {
        do {
            audioFileURL = try AudioRecordingService.shared.startRecording()
            isRecording = true
            startTimer()
        } catch {
            print("[MenuBar] Mic recording failed: \(error)")
        }
    }

    private func startSystemRecording() {
        Task {
            do {
                try await systemCapture.startCapture()
                isRecording = true
                startTimer()
            } catch {
                print("[MenuBar] System capture failed: \(error)")
            }
        }
    }

    private func stopMenuBarRecording() {
        stopTimer()
        isRecording = false

        Task {
            var fileURL: URL?
            if systemCapture.isCapturing {
                fileURL = await systemCapture.stopCapture()
            } else {
                fileURL = AudioRecordingService.shared.stopRecording()
            }

            if let url = fileURL {
                await meetingService.processRecordedAudio(url: url, title: "Meeting \(Date().formatted(date: .abbreviated, time: .shortened))")
            }
        }
    }

    private func startTimer() {
        recordingDuration = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            recordingDuration += 1
        }
    }

    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
#endif
```

- [ ] **Step 2: Verify compile**

- [ ] **Step 3: Commit**

```bash
git add MeetMind/MacApp/MenuBarView.swift
git commit -m "feat(mac): redesign menu bar with dual record buttons and new theme"
```

---

### Task 8: Update MeetMindMacApp Entry Point

**Files:**
- Modify: `MeetMind/MacApp/MeetMindMacApp.swift`

- [ ] **Step 1: Update MeetMindMacApp.swift**

```swift
#if os(macOS)
import SwiftUI

@main
struct MeetMindMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var meetingService = MeetingService.shared

    var body: some Scene {
        // Menu bar extra
        MenuBarExtra("MeetMind", systemImage: "waveform.circle.fill") {
            MenuBarView()
                .environmentObject(meetingService)
        }
        .menuBarExtraStyle(.window)

        // Main window
        WindowGroup {
            MacMainView()
                .environmentObject(meetingService)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 600)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[MeetMind Mac] App launched")
        MeetingAppDetector.shared.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        MeetingAppDetector.shared.stopMonitoring()
    }
}
#endif
```

- [ ] **Step 2: Verify full macOS build**

```bash
cd /Users/modi/R\&D/MeetMind && xcodebuild -scheme "MeetMind" -destination "platform=macOS" build 2>&1 | grep -E "error:|BUILD"
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add MeetMind/MacApp/MeetMindMacApp.swift
git commit -m "feat(mac): update app entry point with environment objects"
```

---

### Task 9: Add All New Files to Xcode Project

**Files:**
- Modify: `MeetMind.xcodeproj/project.pbxproj`

This task adds all new `MacApp/Views/*.swift` files to the Xcode project. Each file needs:
1. A `PBXFileReference` entry
2. A `PBXBuildFile` entry (in the Sources build phase of the MeetMind target)
3. An entry in the `MacApp` PBXGroup (or a new `Views` subgroup)

- [ ] **Step 1: Add file references and build files for all 10 new view files**

The files to add:
- `MacIconRail.swift`
- `MacMeetingListPanel.swift`
- `MacMeetingDetail.swift`
- `MacRecordingView.swift`
- `MacTodosView.swift`
- `MacNotesView.swift`
- `MacLibraryView.swift`
- `MacChatView.swift`
- `MacSettingsView.swift`

Generate unique UUIDs for each file reference and build file entry, then add them to the appropriate sections of `project.pbxproj`.

- [ ] **Step 2: Verify clean build**

```bash
cd /Users/modi/R\&D/MeetMind && xcodebuild -scheme "MeetMind" -destination "platform=macOS" clean build 2>&1 | grep -E "error:|BUILD"
```

- [ ] **Step 3: Commit**

```bash
git add MeetMind.xcodeproj/project.pbxproj
git commit -m "chore: add macOS view files to Xcode project"
```

---

### Task 10: Check processRecordedAudio Method Exists

**Files:**
- Potentially modify: `MeetMind/Services/MeetingService.swift`

- [ ] **Step 1: Verify MeetingService has processRecordedAudio method**

```bash
grep "processRecordedAudio" /Users/modi/R\&D/MeetMind/MeetMind/Services/MeetingService.swift
```

If this method doesn't exist, add it:

```swift
func processRecordedAudio(url: URL, title: String) async {
    let meeting = Meeting(title: title, date: Date(), status: .processing)
    meetings.insert(meeting, at: 0)
    saveMeetings()

    do {
        let processedMeeting = try await pipeline.process(audioURL: url, meeting: meeting)
        if let index = meetings.firstIndex(where: { $0.id == meeting.id }) {
            meetings[index] = processedMeeting
            saveMeetings()
        }
    } catch {
        if let index = meetings.firstIndex(where: { $0.id == meeting.id }) {
            meetings[index].status = .failed
            saveMeetings()
        }
        print("[MeetingService] Processing failed: \(error)")
    }
}
```

- [ ] **Step 2: Verify TodoService has toggleCompletion method**

```bash
grep "toggleCompletion" /Users/modi/R\&D/MeetMind/MeetMind/Services/TodoService.swift
```

If missing, add:

```swift
func toggleCompletion(for id: UUID) {
    guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
    todos[index].isCompleted.toggle()
    todos[index].completedAt = todos[index].isCompleted ? Date() : nil
}
```

- [ ] **Step 3: Commit if changes were made**

```bash
git add MeetMind/Services/MeetingService.swift MeetMind/Services/TodoService.swift
git commit -m "feat: add processRecordedAudio and toggleCompletion methods"
```

---

### Task 11: Final Build & Smoke Test

- [ ] **Step 1: Clean build for macOS**

```bash
cd /Users/modi/R\&D/MeetMind && xcodebuild -scheme "MeetMind" -destination "platform=macOS" clean build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 2: Clean build for iOS (ensure no regressions)**

```bash
cd /Users/modi/R\&D/MeetMind && xcodebuild -scheme "MeetMind" -destination "platform=iOS Simulator,name=iPhone 17 Pro" build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Run the macOS app**

```bash
cd /Users/modi/R\&D/MeetMind && xcodebuild -scheme "MeetMind" -destination "platform=macOS" build 2>&1 | tail -3 && open /Users/modi/Library/Developer/Xcode/DerivedData/MeetMind-*/Build/Products/Debug/MeetMind.app
```

Verify:
- Three-panel layout appears (icon rail + list + detail)
- Icon rail has 6 sections + app icon
- Meeting list shows sample meetings grouped by date
- Clicking a meeting shows tabbed detail view
- Menu bar icon appears with dual record buttons
- Switching between sections works

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat(mac): complete macOS desktop app redesign with three-panel layout"
```
