import WidgetKit
import SwiftUI

@main
struct MeetMindwatchosBundle: WidgetBundle {
    var body: some Widget {
        QuickRecordWidget()
        TodaySummaryWidget()
        TodoInlineWidget()
        MeetMindwatchosControl()
    }
}
