#if os(macOS)
import SwiftUI

struct MacNotesView: View {
    @EnvironmentObject var meetingService: MeetingService
    @State private var selectedNoteId: UUID?
    @State private var searchText = ""

    var body: some View {
        HStack(spacing: 0) {
            // Notes list
            notesList
            Divider()
            // Note detail
            noteDetail
        }
        .background(MMColors.backgroundElevated)
    }

    // MARK: - Notes List

    private var notesList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Notes")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(MMColors.textPrimary)
                Spacer()
                Text("\(meetingsWithNotes.count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MMColors.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(MMColors.background))
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(MMColors.textTertiary)
                TextField("Search notes...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(MMColors.background)
            )
            .padding(.horizontal, 14)
            .padding(.bottom, 14)

            Divider()
                .padding(.horizontal, 14)

            if filteredNotes.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "note.text")
                        .font(.system(size: 28))
                        .foregroundColor(MMColors.textTertiary.opacity(0.4))
                    Text("No notes yet")
                        .font(.system(size: 13))
                        .foregroundColor(MMColors.textSecondary)
                    Text("Notes from meetings will appear here")
                        .font(.system(size: 11))
                        .foregroundColor(MMColors.textTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(filteredNotes) { meeting in
                            noteRow(meeting: meeting)
                                .padding(.horizontal, 14)
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
        }
        .frame(width: 260)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Note Detail

    @ViewBuilder
    private var noteDetail: some View {
        if let noteId = selectedNoteId,
           let meeting = meetingsWithNotes.first(where: { $0.id == noteId }) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(meeting.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(MMColors.textPrimary)
                    Text(meeting.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundColor(MMColors.textTertiary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)

                Divider()

                ScrollView {
                    let noteText = meeting.userNotes ?? meeting.notepadContent ?? ""
                    Text(noteText)
                        .font(.system(size: 14))
                        .foregroundColor(MMColors.textSecondary)
                        .lineSpacing(6)
                        .textSelection(.enabled)
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "note.text")
                    .font(.system(size: 36))
                    .foregroundColor(MMColors.textTertiary.opacity(0.4))
                Text("Select a note")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MMColors.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Row

    private func noteRow(meeting: Meeting) -> some View {
        let noteText = meeting.userNotes ?? meeting.notepadContent ?? ""
        let isSelected = selectedNoteId == meeting.id

        return Button {
            selectedNoteId = meeting.id
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(meeting.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(MMColors.textPrimary)
                    .lineLimit(1)
                Text(noteText)
                    .font(.system(size: 11))
                    .foregroundColor(MMColors.textTertiary)
                    .lineLimit(2)
                Text(meeting.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundColor(MMColors.textTertiary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? MMColors.primary.opacity(0.08) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? MMColors.primary.opacity(0.2) : Color.clear)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var meetingsWithNotes: [Meeting] {
        meetingService.meetings.filter { meeting in
            (meeting.userNotes != nil && !meeting.userNotes!.isEmpty) ||
            (meeting.notepadContent != nil && !meeting.notepadContent!.isEmpty)
        }
    }

    private var filteredNotes: [Meeting] {
        if searchText.isEmpty { return meetingsWithNotes }
        return meetingsWithNotes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.userNotes ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.notepadContent ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
}
#endif
