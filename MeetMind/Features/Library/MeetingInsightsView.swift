import SwiftUI
import Charts

// MARK: - Meeting Insights View

struct MeetingInsightsView: View {
    @EnvironmentObject var meetingService: MeetingService
    @State private var appeared = false

    private var completedMeetings: [Meeting] {
        meetingService.meetings.filter { $0.status == .complete }
    }

    var body: some View {
        ZStack {
            MMColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerStats
                    meetingFrequencyChart
                    topClientsChart
                    topicTrendsSection
                    actionItemStats
                    durationTrendsChart
                    busiestDaysChart
                    topicCloudSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Meeting Intelligence")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }

    // MARK: - Header Stats Row

    private var headerStats: some View {
        let allActions = completedMeetings.flatMap(\.briefActionItems)
        let totalMeetings = completedMeetings.count
        let totalTopics = Set(completedMeetings.flatMap(\.briefKeyTopics)).count
        let totalActions = allActions.count

        return HStack(spacing: 12) {
            StatPill(icon: "video", label: "Meetings", value: totalMeetings, appeared: appeared)
            StatPill(icon: "tag", label: "Topics", value: totalTopics, appeared: appeared)
            StatPill(icon: "checkmark.circle", label: "Actions", value: totalActions, appeared: appeared)
        }
    }

    // MARK: - 1. Meeting Frequency (Last 4 Weeks)

    private var meetingFrequencyChart: some View {
        let data = weeklyMeetingData()

        return InsightCard(title: "Meeting Frequency", icon: "chart.bar.xaxis") {
            if data.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(data, id: \.label) { item in
                    BarMark(
                        x: .value("Week", item.label),
                        y: .value("Meetings", appeared ? item.count : 0)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MMColors.primary, MMColors.primary.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel()
                            .foregroundStyle(MMColors.textSecondary)
                        AxisGridLine()
                            .foregroundStyle(MMColors.divider)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .foregroundStyle(MMColors.textSecondary)
                    }
                }
                .frame(height: 180)
                .animation(.easeOut(duration: 0.8), value: appeared)
            }
        }
    }

    // MARK: - 2. Top Clients

    private var topClientsChart: some View {
        let data = topClientData()

        return InsightCard(title: "Top Clients", icon: "person.2") {
            if data.isEmpty {
                emptyChartPlaceholder
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(data.enumerated()), id: \.element.name) { index, client in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(MMTypography.caption1Medium)
                                .foregroundColor(MMColors.textTertiary)
                                .frame(width: 18)

                            Text(client.name)
                                .font(MMTypography.subheadlineMedium)
                                .foregroundColor(MMColors.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            // Progress bar
                            GeometryReader { geo in
                                let maxCount = data.first?.count ?? 1
                                let fraction = CGFloat(client.count) / CGFloat(maxCount)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(clientBarColor(for: index))
                                    .frame(width: appeared ? geo.size.width * fraction : 0)
                                    .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1), value: appeared)
                            }
                            .frame(width: 100, height: 8)

                            Text("\(client.count)")
                                .font(MMTypography.footnoteMedium)
                                .foregroundColor(MMColors.textSecondary)
                                .frame(width: 28, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 3. Topic Trends

    private var topicTrendsSection: some View {
        let data = topTopicData(limit: 8)

        return InsightCard(title: "Topic Trends", icon: "text.magnifyingglass") {
            if data.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(data, id: \.topic) { item in
                    BarMark(
                        x: .value("Count", appeared ? item.count : 0),
                        y: .value("Topic", item.topic)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MMColors.info, MMColors.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text("\(item.count)")
                            .font(MMTypography.caption1Medium)
                            .foregroundColor(MMColors.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .foregroundStyle(MMColors.textPrimary)
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(data.count) * 36)
                .animation(.easeOut(duration: 0.8), value: appeared)
            }
        }
    }

    // MARK: - 4. Action Item Stats

    private var actionItemStats: some View {
        let allActions = completedMeetings.flatMap(\.briefActionItems)
        let total = allActions.count
        let completed = allActions.filter(\.isCompleted).count
        let overdue = allActions.filter { item in
            !item.isCompleted && (item.dueDate ?? .distantFuture) < Date()
        }.count
        let pending = total - completed

        // By-owner breakdown
        let ownerCounts = Dictionary(grouping: allActions, by: { $0.owner.isEmpty ? "Unassigned" : $0.owner })
            .map { (owner: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(5)

        return InsightCard(title: "Action Item Stats", icon: "checklist") {
            VStack(spacing: 16) {
                // Top row of stats
                HStack(spacing: 0) {
                    ActionStatBubble(
                        label: "Total",
                        value: total,
                        color: MMColors.primary,
                        appeared: appeared
                    )
                    Spacer()
                    ActionStatBubble(
                        label: "Done",
                        value: completed,
                        color: MMColors.success,
                        appeared: appeared
                    )
                    Spacer()
                    ActionStatBubble(
                        label: "Pending",
                        value: pending,
                        color: MMColors.warning,
                        appeared: appeared
                    )
                    Spacer()
                    ActionStatBubble(
                        label: "Overdue",
                        value: overdue,
                        color: MMColors.recording,
                        appeared: appeared
                    )
                }

                if !ownerCounts.isEmpty {
                    Divider()
                        .background(MMColors.divider)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("BY OWNER")
                            .font(MMTypography.overline)
                            .foregroundColor(MMColors.textTertiary)
                            .tracking(1.2)

                        ForEach(Array(ownerCounts), id: \.owner) { entry in
                            HStack {
                                Circle()
                                    .fill(MMColors.primary.opacity(0.6))
                                    .frame(width: 6, height: 6)

                                Text(entry.owner)
                                    .font(MMTypography.subheadline)
                                    .foregroundColor(MMColors.textPrimary)

                                Spacer()

                                Text("\(entry.count)")
                                    .font(MMTypography.footnoteMedium)
                                    .foregroundColor(MMColors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 5. Meeting Duration Trends

    private var durationTrendsChart: some View {
        let data = durationTrendData()

        return InsightCard(title: "Duration Trends", icon: "clock") {
            if data.isEmpty {
                emptyChartPlaceholder
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    let avgMinutes = completedMeetings.isEmpty ? 0 : Int(completedMeetings.map(\.duration).reduce(0, +) / Double(completedMeetings.count)) / 60
                    Text("Avg: \(avgMinutes) min")
                        .font(MMTypography.caption1Medium)
                        .foregroundColor(MMColors.textSecondary)

                    Chart(data, id: \.label) { item in
                        LineMark(
                            x: .value("Date", item.label),
                            y: .value("Minutes", appeared ? item.minutes : 0)
                        )
                        .foregroundStyle(MMColors.success)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        AreaMark(
                            x: .value("Date", item.label),
                            y: .value("Minutes", appeared ? item.minutes : 0)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [MMColors.success.opacity(0.3), MMColors.success.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", item.label),
                            y: .value("Minutes", appeared ? item.minutes : 0)
                        )
                        .foregroundStyle(MMColors.success)
                        .symbolSize(30)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisValueLabel()
                                .foregroundStyle(MMColors.textSecondary)
                            AxisGridLine()
                                .foregroundStyle(MMColors.divider)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(MMColors.textSecondary)
                        }
                    }
                    .frame(height: 180)
                    .animation(.easeOut(duration: 0.8), value: appeared)
                }
            }
        }
    }

    // MARK: - 6. Busiest Days

    private var busiestDaysChart: some View {
        let data = busiestDayData()

        return InsightCard(title: "Busiest Days", icon: "calendar") {
            if data.allSatisfy({ $0.count == 0 }) {
                emptyChartPlaceholder
            } else {
                Chart(data, id: \.day) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Meetings", appeared ? item.count : 0)
                    )
                    .foregroundStyle(
                        item.count == data.map(\.count).max()
                            ? AnyShapeStyle(MMColors.primary)
                            : AnyShapeStyle(MMColors.primary.opacity(0.35))
                    )
                    .cornerRadius(6)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel()
                            .foregroundStyle(MMColors.textSecondary)
                        AxisGridLine()
                            .foregroundStyle(MMColors.divider)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(MMColors.textSecondary)
                    }
                }
                .frame(height: 160)
                .animation(.easeOut(duration: 0.8), value: appeared)
            }
        }
    }

    // MARK: - 7. Topic Cloud

    private var topicCloudSection: some View {
        let data = topTopicData(limit: 20)
        let maxCount = data.first?.count ?? 1

        return InsightCard(title: "Topic Cloud", icon: "cloud") {
            if data.isEmpty {
                emptyChartPlaceholder
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(data.indices, id: \.self) { index in
                        let item = data[index]
                        let scale = 0.6 + 0.4 * (Double(item.count) / Double(maxCount))
                        let opacity = 0.5 + 0.5 * (Double(item.count) / Double(maxCount))

                        Text(item.topic)
                            .font(.system(size: CGFloat(12 + 8 * scale), weight: scale > 0.7 ? .bold : .medium))
                            .foregroundColor(MMColors.primary.opacity(opacity))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(MMColors.primary.opacity(0.08 * opacity))
                            .cornerRadius(20)
                            .scaleEffect(appeared ? 1 : 0.5)
                            .opacity(appeared ? 1 : 0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.04),
                                value: appeared
                            )
                    }
                }
            }
        }
    }

    // MARK: - Empty Placeholder

    private var emptyChartPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar")
                .font(.system(size: 28))
                .foregroundColor(MMColors.textTertiary)
            Text("Not enough data yet")
                .font(MMTypography.footnote)
                .foregroundColor(MMColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }

    // MARK: - Data Computations

    private func weeklyMeetingData() -> [ChartItem] {
        let calendar = Calendar.current
        let now = Date()
        var results: [ChartItem] = []

        for weeksAgo in (0..<4).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: now) else { continue }
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: weekStart)?.start ?? weekStart
            let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) ?? weekStart

            let count = completedMeetings.filter { $0.date >= startOfWeek && $0.date < endOfWeek }.count

            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let label = weeksAgo == 0 ? "This wk" : "\(formatter.string(from: startOfWeek))"

            results.append(ChartItem(label: label, count: count))
        }
        return results
    }

    private func topClientData() -> [ClientCount] {
        let clientMeetings = Dictionary(grouping: completedMeetings.filter { $0.clientName != nil }, by: { $0.clientName! })
        return clientMeetings
            .map { ClientCount(name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(6)
            .map { $0 }
    }

    private func topTopicData(limit: Int) -> [TopicCount] {
        var topicFrequency: [String: Int] = [:]
        for meeting in completedMeetings {
            for topic in meeting.briefKeyTopics {
                topicFrequency[topic, default: 0] += 1
            }
        }
        return topicFrequency
            .map { TopicCount(topic: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { $0 }
    }

    private func durationTrendData() -> [DurationItem] {
        let sorted = completedMeetings.sorted { $0.date < $1.date }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        return sorted.map { meeting in
            DurationItem(
                label: formatter.string(from: meeting.date),
                minutes: Int(meeting.duration / 60)
            )
        }
    }

    private func busiestDayData() -> [DayCount] {
        let calendar = Calendar.current
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var counts = [Int](repeating: 0, count: 7)

        for meeting in completedMeetings {
            let weekday = calendar.component(.weekday, from: meeting.date) - 1 // 0=Sun
            counts[weekday] += 1
        }

        return (0..<7).map { DayCount(day: dayNames[$0], count: counts[$0]) }
    }

    private func clientBarColor(for index: Int) -> LinearGradient {
        let colors: [(Color, Color)] = [
            (MMColors.primary, MMColors.primary.opacity(0.6)),
            (MMColors.success, MMColors.success.opacity(0.6)),
            (MMColors.info, MMColors.info.opacity(0.6)),
            (MMColors.warning, MMColors.warning.opacity(0.6)),
            (Color(hex: "E84393"), Color(hex: "E84393").opacity(0.6)),
            (Color(hex: "00B894"), Color(hex: "00B894").opacity(0.6)),
        ]
        let pair = colors[index % colors.count]
        return LinearGradient(colors: [pair.0, pair.1], startPoint: .leading, endPoint: .trailing)
    }
}

// MARK: - Chart Data Models

private struct ChartItem {
    let label: String
    let count: Int
}

private struct ClientCount {
    let name: String
    let count: Int
}

private struct TopicCount {
    let topic: String
    let count: Int
}

private struct DurationItem {
    let label: String
    let minutes: Int
}

private struct DayCount {
    let day: String
    let count: Int
}

// MARK: - Insight Card Container

private struct InsightCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MMColors.primary)

                Text(title)
                    .font(MMTypography.headline)
                    .foregroundColor(MMColors.textPrimary)
            }

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MMColors.cardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(MMColors.border, lineWidth: 1)
        )
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let icon: String
    let label: String
    let value: Int
    let appeared: Bool

    @State private var displayValue: Int = 0

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(MMColors.primary)

            Text("\(displayValue)")
                .font(MMTypography.title2)
                .foregroundColor(MMColors.textPrimary)
                .contentTransition(.numericText())

            Text(label)
                .font(MMTypography.caption1)
                .foregroundColor(MMColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(MMColors.cardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(MMColors.border, lineWidth: 1)
        )
        .onChange(of: appeared) { _, newValue in
            if newValue {
                animateCount(to: value)
            }
        }
        .onAppear {
            if appeared {
                animateCount(to: value)
            }
        }
    }

    private func animateCount(to target: Int) {
        guard target > 0 else {
            displayValue = 0
            return
        }
        let steps = min(target, 20)
        let interval = 0.6 / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(step)) {
                withAnimation(.easeOut(duration: 0.1)) {
                    displayValue = Int(Double(target) * Double(step) / Double(steps))
                }
            }
        }
    }
}

// MARK: - Action Stat Bubble

private struct ActionStatBubble: View {
    let label: String
    let value: Int
    let color: Color
    let appeared: Bool

    @State private var displayValue: Int = 0

    var body: some View {
        VStack(spacing: 4) {
            Text("\(displayValue)")
                .font(MMTypography.title3)
                .foregroundColor(color)
                .contentTransition(.numericText())

            Text(label)
                .font(MMTypography.caption1)
                .foregroundColor(MMColors.textSecondary)
        }
        .onChange(of: appeared) { _, newValue in
            if newValue {
                animateCount(to: value)
            }
        }
        .onAppear {
            if appeared {
                animateCount(to: value)
            }
        }
    }

    private func animateCount(to target: Int) {
        guard target > 0 else {
            displayValue = 0
            return
        }
        let steps = min(target, 15)
        let interval = 0.5 / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(step)) {
                withAnimation(.easeOut(duration: 0.1)) {
                    displayValue = Int(Double(target) * Double(step) / Double(steps))
                }
            }
        }
    }
}

// FlowLayout is defined in GlobalSearchView.swift — reused here

// MARK: - Preview

#Preview {
    NavigationStack {
        MeetingInsightsView()
            .environmentObject(MeetingService.shared)
    }
}
