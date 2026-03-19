import WidgetKit
import SwiftUI

// MARK: - Shared Data

struct WidgetData: Codable {
    let todayMeetingCount: Int
    let lastMeetingTitle: String?
    let pendingTodos: [WidgetTodo]
    let totalPendingCount: Int
    let updatedAt: Date

    static let placeholder = WidgetData(
        todayMeetingCount: 2,
        lastMeetingTitle: "Strategic Planning — Meyer",
        pendingTodos: [
            WidgetTodo(title: "Send spot instance config doc", priority: "high", dueDate: "Today"),
            WidgetTodo(title: "Review Q3 launch matrix", priority: "medium", dueDate: "Today"),
            WidgetTodo(title: "Register for Databricks cert", priority: "medium", dueDate: "Mar 25"),
        ],
        totalPendingCount: 5,
        updatedAt: Date()
    )

    static func load() -> WidgetData {
        guard let defaults = UserDefaults(suiteName: "group.com.meetmind.shared"),
              let data = defaults.data(forKey: "widgetData"),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data)
        else { return .placeholder }
        return decoded
    }
}

struct WidgetTodo: Codable, Identifiable {
    var id: String { title }
    let title: String
    let priority: String
    let dueDate: String
}

// MARK: - Timeline

struct MeetMindEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

struct MeetMindProvider: TimelineProvider {
    func placeholder(in context: Context) -> MeetMindEntry {
        MeetMindEntry(date: Date(), data: .placeholder)
    }
    func getSnapshot(in context: Context, completion: @escaping (MeetMindEntry) -> ()) {
        completion(MeetMindEntry(date: Date(), data: WidgetData.load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<MeetMindEntry>) -> ()) {
        let entry = MeetMindEntry(date: Date(), data: WidgetData.load())
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Colors

private let purple = Color(red: 108/255, green: 92/255, blue: 231/255)
private let purpleDark = Color(red: 90/255, green: 75/255, blue: 214/255)
private let recordingRed = Color(red: 255/255, green: 71/255, blue: 87/255)
private let successGreen = Color(red: 0/255, green: 206/255, blue: 158/255)
private let warningOrange = Color(red: 255/255, green: 165/255, blue: 2/255)
private let textDark = Color(red: 26/255, green: 26/255, blue: 46/255)
private let textMuted = Color(red: 107/255, green: 114/255, blue: 128/255)

// ═══════════════════════════════════════════════════════
// WIDGET 1: Meeting Recording — Quick Record
// ═══════════════════════════════════════════════════════

struct MeetMindRecordWidget: Widget {
    let kind = "MeetMindRecord"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MeetMindProvider()) { entry in
            RecordWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: [purple, purpleDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
        }
        .configurationDisplayName("Quick Record")
        .description("One tap to start recording a meeting")
        .supportedFamilies({
            var families: [WidgetFamily] = [.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline]
            #if os(watchOS)
            families.append(.accessoryCorner)
            #endif
            return families
        }())
    }
}

struct RecordWidgetView: View {
    let entry: MeetMindEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallRecordView
        case .accessoryCircular:
            circularRecordView
        case .accessoryRectangular:
            rectangularRecordView
        case .accessoryInline:
            inlineRecordView
        #if os(watchOS)
        case .accessoryCorner:
            circularRecordView
        #endif
        default:
            smallRecordView
        }
    }

    // Watch inline complication
    private var inlineRecordView: some View {
        HStack(spacing: 4) {
            Image(systemName: "mic.fill")
            Text("\(entry.data.todayMeetingCount) meetings today")
        }
        .widgetURL(URL(string: "meetmind://record"))
    }

    // Small home screen widget
    private var smallRecordView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain")
                    .font(.system(size: 12, weight: .bold))
                Text("MeetMind")
                    .font(.system(size: 12, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white.opacity(0.8))

            Spacer()

            // Big mic icon
            ZStack {
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "mic.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)

            Spacer()

            Text("Tap to Record")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity)

            if entry.data.todayMeetingCount > 0 {
                Text("\(entry.data.todayMeetingCount) meetings today")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
            }
        }
        .widgetURL(URL(string: "meetmind://record"))
    }

    // Lock screen circular
    private var circularRecordView: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "mic.fill")
                .font(.system(size: 20, weight: .bold))
        }
        .widgetURL(URL(string: "meetmind://record"))
    }

    // Lock screen rectangular
    private var rectangularRecordView: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(recordingRed)
                    .frame(width: 28, height: 28)
                Image(systemName: "mic.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("MeetMind")
                    .font(.system(size: 14, weight: .bold))
                Text("Tap to Record")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .widgetURL(URL(string: "meetmind://record"))
    }
}

// ═══════════════════════════════════════════════════════
// WIDGET 2: Add Todo — Quick capture
// ═══════════════════════════════════════════════════════

struct MeetMindTodoWidget: Widget {
    let kind = "MeetMindAddTodo"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MeetMindProvider()) { entry in
            AddTodoWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color.white }
        }
        .configurationDisplayName("Quick Todo")
        .description("Add a voice or text todo with one tap")
        .supportedFamilies([.systemSmall])
    }
}

struct AddTodoWidgetView: View {
    let entry: MeetMindEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "checklist")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(purple)
                Text("Quick Todo")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(textDark)
                Spacer()
                Text("\(entry.data.totalPendingCount)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(purple)
                    .clipShape(Capsule())
            }

            Spacer()

            // Two action buttons
            HStack(spacing: 10) {
                // Voice todo
                Link(destination: URL(string: "meetmind://voice-todo")!) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(recordingRed)
                                .frame(width: 36, height: 36)
                            Image(systemName: "mic.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Text("Voice")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(textMuted)
                    }
                }
                .frame(maxWidth: .infinity)

                // Text todo
                Link(destination: URL(string: "meetmind://add-todo")!) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(purple)
                                .frame(width: 36, height: 36)
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("Type")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(textMuted)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Spacer()

            Text("\(entry.data.totalPendingCount) tasks pending")
                .font(.system(size: 10))
                .foregroundColor(textMuted)
                .frame(maxWidth: .infinity)
        }
    }
}

// ═══════════════════════════════════════════════════════
// WIDGET 3: Today's Todos — Overview
// ═══════════════════════════════════════════════════════

struct MeetMindTodayWidget: Widget {
    let kind = "MeetMindToday"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MeetMindProvider()) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color.white }
        }
        .configurationDisplayName("Today's Tasks")
        .description("See your tasks and meetings for today")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct TodayWidgetView: View {
    let entry: MeetMindEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(textDark)
                    Text(dateString)
                        .font(.system(size: 11))
                        .foregroundColor(textMuted)
                }

                Spacer()

                // Stats pills
                HStack(spacing: 8) {
                    statPill(icon: "mic.fill", value: "\(entry.data.todayMeetingCount)", color: purple)
                    statPill(icon: "checklist", value: "\(entry.data.totalPendingCount)", color: warningOrange)
                }
            }

            Divider()

            // Todo list
            if entry.data.pendingTodos.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 24))
                            .foregroundColor(successGreen.opacity(0.5))
                        Text("All caught up!")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textMuted)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                let maxItems = family == .systemLarge ? 7 : 3
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(entry.data.pendingTodos.prefix(maxItems).enumerated()), id: \.offset) { _, todo in
                        todoRow(todo)
                    }

                    if entry.data.pendingTodos.count > maxItems {
                        Text("+ \(entry.data.pendingTodos.count - maxItems) more")
                            .font(.system(size: 11))
                            .foregroundColor(purple)
                    }
                }
            }

            if family == .systemLarge {
                Spacer()

                // Last meeting info
                if let lastTitle = entry.data.lastMeetingTitle {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 11))
                            .foregroundColor(purple)
                        Text("Last: \(lastTitle)")
                            .font(.system(size: 11))
                            .foregroundColor(textMuted)
                            .lineLimit(1)
                    }
                }
            }
        }
        .widgetURL(URL(string: "meetmind://todos"))
    }

    private func todoRow(_ todo: WidgetTodo) -> some View {
        HStack(spacing: 8) {
            // Priority dot
            Circle()
                .fill(priorityColor(todo.priority))
                .frame(width: 6, height: 6)

            Text(todo.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(textDark)
                .lineLimit(1)

            Spacer()

            Text(todo.dueDate)
                .font(.system(size: 10))
                .foregroundColor(textMuted)
        }
    }

    private func statPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(value)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }

    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return recordingRed
        case "medium": return warningOrange
        default: return textMuted
        }
    }

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }
}

// MARK: - Previews

#Preview("Record Small", as: .systemSmall) {
    MeetMindRecordWidget()
} timeline: {
    MeetMindEntry(date: Date(), data: .placeholder)
}

#Preview("Add Todo", as: .systemSmall) {
    MeetMindTodoWidget()
} timeline: {
    MeetMindEntry(date: Date(), data: .placeholder)
}

#Preview("Today Medium", as: .systemMedium) {
    MeetMindTodayWidget()
} timeline: {
    MeetMindEntry(date: Date(), data: .placeholder)
}

#Preview("Today Large", as: .systemLarge) {
    MeetMindTodayWidget()
} timeline: {
    MeetMindEntry(date: Date(), data: .placeholder)
}
