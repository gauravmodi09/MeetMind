import WidgetKit
import SwiftUI

@main
struct MeetMindWatchWidgetsBundle: WidgetBundle {
    var body: some Widget {
        RecordComplication()
        SummaryComplication()
        InlineComplication()
    }
}
