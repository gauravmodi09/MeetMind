import WidgetKit
import SwiftUI

@main
struct MeetMindWidgetBundle: WidgetBundle {
    var body: some Widget {
        MeetMindRecordWidget()
        MeetMindTodoWidget()
        MeetMindTodayWidget()
    }
}
