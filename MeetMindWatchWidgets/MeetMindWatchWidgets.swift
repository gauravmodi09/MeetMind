import WidgetKit
import SwiftUI

// MARK: - Entry

struct WatchWidgetEntry: TimelineEntry {
    let date: Date
    let meetingCount: Int
    let pendingTodos: Int
}

// MARK: - Provider

struct WatchWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchWidgetEntry {
        WatchWidgetEntry(date: Date(), meetingCount: 2, pendingTodos: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchWidgetEntry) -> Void) {
        completion(WatchWidgetEntry(date: Date(), meetingCount: 0, pendingTodos: 0))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchWidgetEntry>) -> Void) {
        let entry = WatchWidgetEntry(date: Date(), meetingCount: 0, pendingTodos: 0)
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Record Complication (Circular)

struct RecordComplication: Widget {
    let kind = "MeetMindWatchRecord"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchWidgetProvider()) { entry in
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "mic.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.purple)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Record Meeting")
        .description("Tap to start recording.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner])
    }
}

// MARK: - Summary Complication (Rectangular)

struct SummaryComplication: Widget {
    let kind = "MeetMindWatchSummary"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchWidgetProvider()) { entry in
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.purple)
                    Text("MeetMind")
                        .font(.system(size: 11, weight: .bold))
                }
                HStack(spacing: 10) {
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
        }
        .configurationDisplayName("MeetMind Today")
        .description("Meetings and tasks at a glance.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Inline Complication

struct InlineComplication: Widget {
    let kind = "MeetMindWatchInline"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchWidgetProvider()) { entry in
            HStack(spacing: 4) {
                Image(systemName: "mic.fill")
                Text("\(entry.pendingTodos) tasks")
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Pending Tasks")
        .description("Quick task count.")
        .supportedFamilies([.accessoryInline])
    }
}
