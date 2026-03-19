import WidgetKit
import SwiftUI

// MARK: - Shared Data

struct WatchWidgetEntry: TimelineEntry {
    let date: Date
    let meetingCount: Int
    let pendingTodos: Int
    let nextMeetingTitle: String?
    let currentStreak: Int
    let isRecording: Bool
}

// MARK: - Provider

struct WatchWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchWidgetEntry {
        WatchWidgetEntry(date: Date(), meetingCount: 3, pendingTodos: 5, nextMeetingTitle: "Team Standup", currentStreak: 7, isRecording: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchWidgetEntry) -> Void) {
        let data = loadWidgetData()
        completion(data)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchWidgetEntry>) -> Void) {
        let data = loadWidgetData()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [data], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadWidgetData() -> WatchWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.com.meetmind.shared")
        let meetingCount = defaults?.integer(forKey: "todayMeetingCount") ?? 0
        let pendingTodos = defaults?.integer(forKey: "pendingTodoCount") ?? 0
        let nextMeeting = defaults?.string(forKey: "nextMeetingTitle")
        let streak = defaults?.integer(forKey: "currentStreak") ?? 0
        let isRecording = defaults?.bool(forKey: "isRecording") ?? false

        return WatchWidgetEntry(
            date: Date(),
            meetingCount: meetingCount,
            pendingTodos: pendingTodos,
            nextMeetingTitle: nextMeeting,
            currentStreak: streak,
            isRecording: isRecording
        )
    }
}

// MARK: - Quick Record Widget (Circular)

struct QuickRecordWidget: Widget {
    let kind = "MeetMindWatchRecord"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchWidgetProvider()) { entry in
            QuickRecordWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Record Meeting")
        .description("One-tap to start recording a meeting.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner])
    }
}

struct QuickRecordWidgetView: View {
    let entry: WatchWidgetEntry

    var body: some View {
        ZStack {
            if entry.isRecording {
                // Recording state — pulsing red
                AccessoryWidgetBackground()
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.red)
            } else {
                AccessoryWidgetBackground()
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.purple)
            }
        }
        .widgetURL(URL(string: entry.isRecording ? "meetmind://stop-recording" : "meetmind://record"))
    }
}

// MARK: - Today Summary Widget (Rectangular)

struct TodaySummaryWidget: Widget {
    let kind = "MeetMindWatchToday"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchWidgetProvider()) { entry in
            TodaySummaryWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("MeetMind Today")
        .description("Today's meetings and tasks at a glance.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct TodaySummaryWidgetView: View {
    let entry: WatchWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.purple)
                Text("MeetMind")
                    .font(.system(size: 11, weight: .bold))
                Spacer()
                if entry.currentStreak > 0 {
                    HStack(spacing: 1) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.orange)
                        Text("\(entry.currentStreak)")
                            .font(.system(size: 9, weight: .bold))
                    }
                }
            }

            // Stats row
            HStack(spacing: 12) {
                HStack(spacing: 3) {
                    Image(systemName: "waveform")
                        .font(.system(size: 9))
                        .foregroundColor(.purple)
                    Text("\(entry.meetingCount)")
                        .font(.system(size: 12, weight: .semibold))
                    Text("meetings")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 3) {
                    Image(systemName: "checklist")
                        .font(.system(size: 9))
                        .foregroundColor(.cyan)
                    Text("\(entry.pendingTodos)")
                        .font(.system(size: 12, weight: .semibold))
                    Text("tasks")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }

            // Next meeting or action
            if let next = entry.nextMeetingTitle, !next.isEmpty {
                HStack(spacing: 3) {
                    Image(systemName: "clock")
                        .font(.system(size: 8))
                        .foregroundColor(.orange)
                    Text(next)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            } else {
                HStack(spacing: 3) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.purple)
                    Text("Tap to record")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
        .widgetURL(URL(string: "meetmind://record"))
    }
}

// MARK: - Todos Widget (Inline)

struct TodoInlineWidget: Widget {
    let kind = "MeetMindWatchTodos"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchWidgetProvider()) { entry in
            TodoInlineWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Pending Tasks")
        .description("See your pending task count.")
        .supportedFamilies([.accessoryInline])
    }
}

struct TodoInlineWidgetView: View {
    let entry: WatchWidgetEntry

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checklist")
            Text("\(entry.pendingTodos) tasks pending")
        }
        .widgetURL(URL(string: "meetmind://todos"))
    }
}

// MARK: - Previews

#Preview(as: .accessoryCircular) {
    QuickRecordWidget()
} timeline: {
    WatchWidgetEntry(date: .now, meetingCount: 2, pendingTodos: 4, nextMeetingTitle: nil, currentStreak: 5, isRecording: false)
    WatchWidgetEntry(date: .now, meetingCount: 2, pendingTodos: 4, nextMeetingTitle: nil, currentStreak: 5, isRecording: true)
}

#Preview(as: .accessoryRectangular) {
    TodaySummaryWidget()
} timeline: {
    WatchWidgetEntry(date: .now, meetingCount: 3, pendingTodos: 5, nextMeetingTitle: "Team Standup 2:00 PM", currentStreak: 7, isRecording: false)
}
