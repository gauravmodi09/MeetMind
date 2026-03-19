import AppIntents
import SwiftUI
import WidgetKit

struct MeetMindwatchosControl: ControlWidget {
    static let kind: String = "com.meetmind.watchRecordControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenRecordingIntent()) {
                Label("Record", systemImage: "mic.fill")
            }
        }
        .displayName("Record Meeting")
        .description("Start recording a meeting on MeetMind.")
    }
}

struct OpenRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Open MeetMind Recording"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
