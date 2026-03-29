import SwiftUI

struct QuickNote: Identifiable, Codable {
    var id = UUID()
    var title: String
    var content: String
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var folder: String?
    var tags: [String] = []

    var preview: String {
        let text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return "Empty note" }
        return String(text.prefix(100))
    }

    var dateLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(createdAt) { return "Today" }
        if cal.isDateInYesterday(createdAt) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: createdAt)
    }
}

// MARK: - Quick Note Service

@MainActor
class QuickNoteService: ObservableObject {
    static let shared = QuickNoteService()

    @Published var notes: [QuickNote] = []

    private let storageKey = "quickNotes"

    init() {
        loadNotes()
    }

    func save(_ note: QuickNote) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            notes[idx] = note
            notes[idx].updatedAt = Date()
        } else {
            notes.insert(note, at: 0)
        }
        persist()
    }

    func delete(_ note: QuickNote) {
        notes.removeAll { $0.id == note.id }
        persist()
    }

    private func loadNotes() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([QuickNote].self, from: data) else { return }
        notes = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(notes) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

// MARK: - Quick Note Editor (Granola-style)

struct QuickNoteEditorView: View {
    @StateObject private var noteService = QuickNoteService.shared
    @StateObject private var dictation = VoiceDictationService()
    @Environment(\.dismiss) private var dismiss

    @State private var note: QuickNote
    @State private var isNew: Bool
    @FocusState private var isContentFocused: Bool

    init(note: QuickNote? = nil) {
        let n = note ?? QuickNote(title: "", content: "")
        _note = State(initialValue: n)
        _isNew = State(initialValue: note == nil)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button {
                    saveAndDismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "house")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(MMColors.textTertiary)
                    .padding(8)
                    .background(MMColors.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(MMColors.border, lineWidth: 1)
                    )
                }

                Spacer()

                // More options
                Menu {
                    Button(role: .destructive) {
                        if !isNew {
                            noteService.delete(note)
                        }
                        dismiss()
                    } label: {
                        Label("Delete Note", systemImage: "trash")
                    }

                    Button {
                        UIPasteboard.general.string = note.content
                    } label: {
                        Label("Copy Text", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MMColors.textTertiary)
                        .frame(width: 32, height: 32)
                        .background(MMColors.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(MMColors.border, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Note content area — fills remaining space
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Title
                    TextField("New note", text: $note.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(MMColors.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    // Tags row
                    HStack(spacing: 8) {
                        tagPill(icon: "calendar", label: note.dateLabel)
                        tagPill(icon: "person.2", label: "Me")

                        Button {
                            // Future: folder picker
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 10, weight: .medium))
                                Text("Add to folder")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(MMColors.textTertiary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(MMColors.cardBg)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(MMColors.border, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Divider
                    Rectangle()
                        .fill(MMColors.border)
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    // Content editor
                    ZStack(alignment: .topLeading) {
                        if note.content.isEmpty && dictation.state != .listening {
                            Text("Write notes...")
                                .font(.system(size: 16))
                                .foregroundColor(MMColors.textTertiary.opacity(0.5))
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $note.content)
                            .font(.system(size: 16))
                            .foregroundColor(MMColors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .tint(MMColors.primary)
                            .focused($isContentFocused)
                            .padding(.horizontal, 20)
                            .frame(minHeight: 300)
                    }
                }
            }
            .layoutPriority(1)

            // Bottom bar — Granola-style
            bottomBar
        }
        .background(MMColors.background)
        .onAppear {
            if isNew {
                isContentFocused = true
            }
        }
        .onChange(of: dictation.currentText) { _, newText in
            if dictation.state == .listening && !newText.isEmpty {
                note.content = newText
            }
        }
        .task {
            if !dictation.isAuthorized {
                _ = await dictation.requestAuthorization()
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Tag Pill

    private func tagPill(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
            Text(label)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(MMColors.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(MMColors.cardBg)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(MMColors.border, lineWidth: 1)
        )
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(MMColors.border)
                .frame(height: 1)

            HStack(spacing: 12) {
                // Dictation button
                Button {
                    if dictation.state == .listening {
                        dictation.stopDictation()
                    } else {
                        dictation.startDictation()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: dictation.state == .listening ? "waveform" : "mic")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(dictation.state == .listening ? MMColors.recording : MMColors.textSecondary)
                            .symbolEffect(.pulse, isActive: dictation.state == .listening)

                        if dictation.state == .listening {
                            Text("Listening...")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(MMColors.recording)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        dictation.state == .listening
                            ? MMColors.recording.opacity(0.1)
                            : MMColors.cardBg
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(
                            dictation.state == .listening ? MMColors.recording.opacity(0.3) : MMColors.border,
                            lineWidth: 1
                        )
                    )
                }

                Spacer()

                // Character count
                if !note.content.isEmpty {
                    Text("\(note.content.count) chars")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(MMColors.textTertiary)
                }

                // Save
                Button {
                    saveAndDismiss()
                } label: {
                    Text("Save")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(MMColors.primary)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(MMColors.backgroundElevated)
        }
    }

    private func saveAndDismiss() {
        // Auto-title if empty
        if note.title.isEmpty {
            let f = DateFormatter()
            f.dateFormat = "MMM d, h:mm a"
            note.title = f.string(from: note.createdAt)
        }

        if !note.content.isEmpty || !note.title.isEmpty {
            noteService.save(note)
        }
        dismiss()
    }
}

// MARK: - Notes List View

struct QuickNotesListView: View {
    @StateObject private var noteService = QuickNoteService.shared
    @State private var showNewNote = false
    @State private var selectedNote: QuickNote?

    var body: some View {
        NavigationStack {
            ZStack {
                MMColors.background.ignoresSafeArea()

                if noteService.notes.isEmpty {
                    emptyState
                } else {
                    notesList
                }
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewNote = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(MMColors.primary)
                    }
                }
            }
            .fullScreenCover(isPresented: $showNewNote) {
                QuickNoteEditorView()
            }
            .fullScreenCover(item: $selectedNote) { note in
                QuickNoteEditorView(note: note)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 44))
                .foregroundColor(MMColors.textTertiary.opacity(0.3))

            Text("No notes yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(MMColors.textPrimary)

            Text("Quick notes for jotting down thoughts,\nmeeting observations, or ideas")
                .font(.system(size: 14))
                .foregroundColor(MMColors.textTertiary)
                .multilineTextAlignment(.center)

            Button {
                showNewNote = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("New Note")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(MMColors.primary)
                .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
    }

    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(noteService.notes) { note in
                    noteCard(note)
                        .onTapGesture {
                            selectedNote = note
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
    }

    private func noteCard(_ note: QuickNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MMColors.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text(note.dateLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(MMColors.textTertiary)
            }

            if !note.content.isEmpty {
                Text(note.preview)
                    .font(.system(size: 13))
                    .foregroundColor(MMColors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(MMColors.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(MMColors.border, lineWidth: 1)
        )
        .contextMenu {
            Button(role: .destructive) {
                noteService.delete(note)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    QuickNoteEditorView()
}
