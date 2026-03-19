import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct WatchEntry: TimelineEntry {
    let date: Date
    let meetingCount: Int
    let pendingTodos: Int
}

// MARK: - Provider

struct WatchProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchEntry {
        WatchEntry(date: Date(), meetingCount: 2, pendingTodos: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchEntry) -> Void) {
        let defaults = UserDefaults(suiteName: "group.com.meetmind.shared")
        let entry = WatchEntry(
            date: Date(),
            meetingCount: defaults?.integer(forKey: "todayMeetingCount") ?? 0,
            pendingTodos: defaults?.integer(forKey: "pendingTodoCount") ?? 0
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.com.meetmind.shared")
        let entry = WatchEntry(
            date: Date(),
            meetingCount: defaults?.integer(forKey: "todayMeetingCount") ?? 0,
            pendingTodos: defaults?.integer(forKey: "pendingTodoCount") ?? 0
        )
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Circular Complication (Record Button)

struct MeetMindRecordComplication: Widget {
    let kind = "MeetMindWatchRecord"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchProvider()) { entry in
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "mic.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.purple)
            }
            .containerBackground(.fill.tertiary, for: .widget)
            .widgetURL(URL(string: "meetmind://record"))
        }
        .configurationDisplayName("Record Meeting")
        .description("One tap to start recording.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner])
    }
}

// MARK: - Rectangular Complication (Today Summary)

struct MeetMindTodayComplication: Widget {
    let kind = "MeetMindWatchToday"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchProvider()) { entry in
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.purple)
                    Text("MeetMind")
                        .font(.system(size: 11, weight: .bold))
                }

                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        Image(systemName: "waveform")
                            .font(.system(size: 9))
                            .foregroundColor(.purple)
                        Text("\(entry.meetingCount)")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "checklist")
                            .font(.system(size: 9))
                            .foregroundColor(.cyan)
                        Text("\(entry.pendingTodos)")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }

                Text("Tap to record")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .containerBackground(.fill.tertiary, for: .widget)
            .widgetURL(URL(string: "meetmind://record"))
        }
        .configurationDisplayName("MeetMind Today")
        .description("Meetings and tasks at a glance.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Inline Complication (Text)

struct MeetMindInlineComplication: Widget {
    let kind = "MeetMindWatchInline"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchProvider()) { entry in
            HStack(spacing: 4) {
                Image(systemName: "mic.fill")
                Text("\(entry.pendingTodos) tasks")
            }
            .containerBackground(.fill.tertiary, for: .widget)
            .widgetURL(URL(string: "meetmind://todos"))
        }
        .configurationDisplayName("Pending Tasks")
        .description("See your pending task count.")
        .supportedFamilies([.accessoryInline])
    }
}
