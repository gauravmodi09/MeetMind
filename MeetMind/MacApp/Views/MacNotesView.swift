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
