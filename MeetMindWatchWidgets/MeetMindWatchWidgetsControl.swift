import AppIntents
import SwiftUI
import WidgetKit

struct MeetMindWatchWidgetsControl: ControlWidget {
    static let kind: String = "com.meetmind.watchRecordControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenMeetMindIntent()) {
                Label("Record", systemImage: "mic.fill")
            }
        }
        .displayName("Record Meeting")
        .description("Open MeetMind to record a meeting.")
    }
}

struct OpenMeetMindIntent: AppIntent {
    static var title: LocalizedStringResource = "Open MeetMind"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
