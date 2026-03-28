#if os(macOS)
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var meetingService: MeetingService
    @State private var isRecording = false

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(MMColors.primary)
                Text("MeetMind")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            Divider()

            // Recording status
            if isRecording {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("Recording...")
                        .font(.subheadline)
                    Spacer()
                    Button("Stop") {
                        isRecording = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.small)
                }
                .padding(.horizontal, 12)
            } else {
                Button {
                    isRecording = true
                } label: {
                    HStack {
                        Image(systemName: "record.circle")
                        Text("Start Recording")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(MMColors.primary)
                .controlSize(.large)
                .padding(.horizontal, 12)
            }

            // Recent meetings
            if !meetingService.meetings.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)

                    ForEach(meetingService.meetings.prefix(3)) { meeting in
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .font(.caption)
                                .foregroundColor(MMColors.primary)
                            Text(meeting.title)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            Text(meeting.date, style: .relative)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                    }
                }
            }

            Divider()

            // Actions
            HStack {
                Button("Open MeetMind") {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { $0.title.contains("MeetMind") || $0.isKeyWindow }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .font(.caption)

                Spacer()

                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .frame(width: 280)
    }
}
#endif
