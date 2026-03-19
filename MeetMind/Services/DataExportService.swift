import Foundation

/// Exports meetings and todos as JSON or CSV files for sharing.
enum DataExportService {

    // MARK: - JSON Export

    /// Creates a full JSON snapshot with metadata.
    /// Returns a file URL in the temp directory, or `nil` on failure.
    static func exportAllAsJSON(meetings: [Meeting], todos: [TodoItem]) -> URL? {
        let export = ExportPayload(
            exportDate: ISO8601DateFormatter().string(from: Date()),
            version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            meetingCount: meetings.count,
            todoCount: todos.count,
            meetings: meetings.map { MeetingExport(from: $0) },
            todos: todos.map { TodoExport(from: $0) }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(export)
            let url = tempFileURL(name: "meetmind_export.json")
            try data.write(to: url)
            print("[Export] JSON written to \(url.path)")
            return url
        } catch {
            print("[Export] JSON export failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - CSV Export

    /// Creates separate CSV files for meetings and todos.
    /// Returns file URLs in the temp directory.
    static func exportAllAsCSV(meetings: [Meeting], todos: [TodoItem]) -> [URL] {
        var urls: [URL] = []

        // Meetings CSV
        if let meetingsURL = exportMeetingsCSV(meetings) {
            urls.append(meetingsURL)
        }

        // Todos CSV
        if let todosURL = exportTodosCSV(todos) {
            urls.append(todosURL)
        }

        return urls
    }

    // MARK: - Private: Meetings CSV

    private static func exportMeetingsCSV(_ meetings: [Meeting]) -> URL? {
        var csv = "ID,Title,Date,Duration (s),Client,Status,Summary,Key Topics,Decisions,Created At\n"

        let dateFormatter = ISO8601DateFormatter()

        for m in meetings {
            let row = [
                m.id.uuidString,
                csvEscape(m.title),
                dateFormatter.string(from: m.date),
                String(format: "%.0f", m.duration),
                csvEscape(m.clientName ?? ""),
                m.status.rawValue,
                csvEscape(m.briefSummary ?? ""),
                csvEscape(m.briefKeyTopics.joined(separator: "; ")),
                csvEscape(m.briefDecisions.joined(separator: "; ")),
                dateFormatter.string(from: m.createdAt)
            ]
            csv += row.joined(separator: ",") + "\n"
        }

        do {
            let url = tempFileURL(name: "meetmind_meetings.csv")
            try csv.write(to: url, atomically: true, encoding: .utf8)
            print("[Export] Meetings CSV written to \(url.path)")
            return url
        } catch {
            print("[Export] Meetings CSV export failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Private: Todos CSV

    private static func exportTodosCSV(_ todos: [TodoItem]) -> URL? {
        var csv = "ID,Title,Due Date,Priority,Client,Source,Source Meeting ID,Completed,Completed At,Created At\n"

        let dateFormatter = ISO8601DateFormatter()

        for t in todos {
            let row = [
                t.id.uuidString,
                csvEscape(t.title),
                dateFormatter.string(from: t.dueDate),
                t.priority.rawValue,
                csvEscape(t.clientTag ?? ""),
                t.source.rawValue,
                t.sourceMeetingId?.uuidString ?? "",
                t.isCompleted ? "true" : "false",
                t.completedAt.map { dateFormatter.string(from: $0) } ?? "",
                dateFormatter.string(from: t.createdAt)
            ]
            csv += row.joined(separator: ",") + "\n"
        }

        do {
            let url = tempFileURL(name: "meetmind_todos.csv")
            try csv.write(to: url, atomically: true, encoding: .utf8)
            print("[Export] Todos CSV written to \(url.path)")
            return url
        } catch {
            print("[Export] Todos CSV export failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Helpers

    /// Escapes a string for CSV: wraps in quotes if it contains commas, quotes, or newlines.
    private static func csvEscape(_ value: String) -> String {
        let needsQuoting = value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r")
        if needsQuoting {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

    /// Returns a URL in the temp directory for the given file name.
    private static func tempFileURL(name: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("MeetMindExport", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir.appendingPathComponent(name)
    }
}

// MARK: - Codable Export Models

private struct ExportPayload: Codable {
    let exportDate: String
    let version: String
    let meetingCount: Int
    let todoCount: Int
    let meetings: [MeetingExport]
    let todos: [TodoExport]
}

private struct MeetingExport: Codable {
    let id: String
    let title: String
    let date: Date
    let duration: TimeInterval
    let clientName: String?
    let status: String
    let summary: String?
    let decisions: [String]
    let actionItems: [ActionItemExport]
    let keyTopics: [String]
    let rawTranscript: String?
    let userNotes: String?
    let createdAt: Date

    init(from m: Meeting) {
        self.id = m.id.uuidString
        self.title = m.title
        self.date = m.date
        self.duration = m.duration
        self.clientName = m.clientName
        self.status = m.status.rawValue
        self.summary = m.briefSummary
        self.decisions = m.briefDecisions
        self.actionItems = m.briefActionItems.map { ActionItemExport(from: $0) }
        self.keyTopics = m.briefKeyTopics
        self.rawTranscript = m.rawTranscript
        self.userNotes = m.userNotes
        self.createdAt = m.createdAt
    }
}

private struct ActionItemExport: Codable {
    let text: String
    let owner: String
    let dueDate: String?
    let isMine: Bool
    let isCompleted: Bool

    init(from a: ActionItem) {
        self.text = a.text
        self.owner = a.owner
        self.dueDate = a.dueDate.map { ISO8601DateFormatter().string(from: $0) }
        self.isMine = a.isMine
        self.isCompleted = a.isCompleted
    }
}

private struct TodoExport: Codable {
    let id: String
    let title: String
    let dueDate: Date
    let priority: String
    let clientTag: String?
    let source: String
    let sourceMeetingId: String?
    let isCompleted: Bool
    let completedAt: Date?
    let createdAt: Date

    init(from t: TodoItem) {
        self.id = t.id.uuidString
        self.title = t.title
        self.dueDate = t.dueDate
        self.priority = t.priority.rawValue
        self.clientTag = t.clientTag
        self.source = t.source.rawValue
        self.sourceMeetingId = t.sourceMeetingId?.uuidString
        self.isCompleted = t.isCompleted
        self.completedAt = t.completedAt
        self.createdAt = t.createdAt
    }
}
