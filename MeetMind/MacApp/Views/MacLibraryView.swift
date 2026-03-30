#if os(macOS)
import SwiftUI

struct MacLibraryView: View {
    @EnvironmentObject var meetingService: MeetingService

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Library")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
            }
            .padding(24)

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        statCard(value: "\(meetingService.meetings.count)", label: "Total Meetings", color: MMColors.primary)
                        statCard(value: "\(totalActionItems)", label: "Action Items", color: Color(red: 0.063, green: 0.725, blue: 0.506))
                        statCard(value: formattedTotalTime, label: "Time Recorded", color: Color(red: 0.231, green: 0.510, blue: 0.965))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("By Meeting Type")
                            .font(.system(size: 14, weight: .semibold))
                        ForEach(templateCounts) { item in
                            templateRow(item: item)
                        }
                    }
                }
                .padding(24)
            }
        }
        .background(Color.white)
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(color: .black.opacity(0.05), radius: 4, y: 2))
    }

    private func templateRow(item: TemplateCount) -> some View {
        HStack {
            Text(item.template.rawValue)
                .font(.system(size: 13))
            Spacer()
            Text("\(item.count)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MMColors.primary)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.98, green: 0.98, blue: 0.98)))
    }

    private var totalActionItems: Int {
        meetingService.meetings.reduce(0) { $0 + $1.briefActionItems.count }
    }

    private var formattedTotalTime: String {
        let totalMinutes = Int(meetingService.meetings.reduce(0) { $0 + $1.duration }) / 60
        if totalMinutes < 60 { return "\(totalMinutes)m" }
        return "\(totalMinutes / 60)h \(totalMinutes % 60)m"
    }

    private struct TemplateCount: Identifiable {
        let template: MeetingTemplate
        let count: Int
        var id: String { template.rawValue }
    }

    private var templateCounts: [TemplateCount] {
        let grouped = Dictionary(grouping: meetingService.meetings, by: \.template)
        return grouped.map { TemplateCount(template: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
}
#endif
