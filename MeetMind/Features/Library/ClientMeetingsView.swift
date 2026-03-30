import SwiftUI

struct ClientMeetingsView: View {
    let folder: ClientFolder
    let meetings: [Meeting]

    @EnvironmentObject var meetingService: MeetingService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMeeting: Meeting?

    var body: some View {
        ZStack {
            MMColors.background.ignoresSafeArea()

            if meetings.isEmpty {
                MMEmptyState(
                    icon: "doc.text",
                    title: "No meetings yet",
                    message: "Meetings with \(folder.name) will appear here."
                )
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(meetings) { meeting in
                            Button {
                                selectedMeeting = meeting
                            } label: {
                                MeetingCard(
                                    meeting: meeting,
                                    onCopy: {
                                        let brief = MeetingBriefFormatter.format(meeting: meeting)
                                        #if os(iOS)
                                        UIPasteboard.general.string = brief
                                        #else
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(brief, forType: .string)
                                        #endif
                                    },
                                    onChangeClient: { newClient in
                                        meetingService.updateMeetingClient(meeting, newClient: newClient)
                                    },
                                    availableClients: meetingService.allClientNames
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: {
                #if os(iOS)
                return .navigationBarLeading
                #else
                return .automatic
                #endif
            }()) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Library")
                            .font(MMTypography.subheadline)
                    }
                    .foregroundColor(MMColors.primary)
                }
            }

            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: folder.colorHex))
                        .frame(width: 10, height: 10)

                    Text(folder.name)
                        .font(MMTypography.headline)
                        .foregroundColor(MMColors.textPrimary)

                    Text("\(meetings.count)")
                        .font(MMTypography.caption1)
                        .foregroundColor(MMColors.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(MMColors.background)
                        .cornerRadius(8)
                }
            }
        }
        .navigationDestination(item: $selectedMeeting) { meeting in
            MeetingDetailView(meeting: meeting)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ClientMeetingsView(
            folder: ClientFolder(
                name: "Acme Corp",
                colorHex: "6C5CE7",
                meetingCount: 3,
                lastMeetingDate: Date()
            ),
            meetings: [
                Meeting(
                    title: "Weekly Sync",
                    date: Date(),
                    duration: 1800,
                    clientName: "Acme Corp",
                    status: .complete,
                    briefActionItems: [ActionItem(text: "Follow up", owner: "Me")]
                ),
                Meeting(
                    title: "Product Review",
                    date: Date().addingTimeInterval(-86400 * 3),
                    duration: 2700,
                    clientName: "Acme Corp",
                    status: .complete
                ),
                Meeting(
                    title: "Kickoff Call",
                    date: Date().addingTimeInterval(-86400 * 10),
                    duration: 3600,
                    clientName: "Acme Corp",
                    status: .complete
                )
            ]
        )
    }
}
