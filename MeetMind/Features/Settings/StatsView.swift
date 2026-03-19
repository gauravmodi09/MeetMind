import SwiftUI

struct StatsView: View {
    @ObservedObject private var streakService = StreakService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Streak + Level Header
                streakHeader

                // MARK: - Level Progress
                levelCard

                // MARK: - This Week
                weeklyCard

                // MARK: - All-Time Totals
                allTimeCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(MMColors.background.ignoresSafeArea())
        .navigationTitle("Your Stats")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Streak Header

    private var streakHeader: some View {
        HStack(spacing: 24) {
            // Current streak
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            streakService.getCurrentStreak() > 0
                                ? LinearGradient(colors: [Color.orange, Color.red], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [MMColors.textTertiary, MMColors.textTertiary], startPoint: .top, endPoint: .bottom)
                        )
                    Text("\(streakService.getCurrentStreak())")
                        .font(MMTypography.largeTitle)
                        .foregroundColor(MMColors.textPrimary)
                }
                Text("Day Streak")
                    .font(MMTypography.caption1Medium)
                    .foregroundColor(MMColors.textSecondary)
            }

            Divider()
                .frame(height: 48)

            // Longest streak
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 22))
                        .foregroundColor(MMColors.warning)
                    Text("\(streakService.longestStreak)")
                        .font(MMTypography.title1)
                        .foregroundColor(MMColors.textPrimary)
                }
                Text("Best Streak")
                    .font(MMTypography.caption1Medium)
                    .foregroundColor(MMColors.textSecondary)
            }

            Divider()
                .frame(height: 48)

            // Productivity score
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 22))
                        .foregroundColor(MMColors.success)
                    Text("\(streakService.productivityScore)")
                        .font(MMTypography.title1)
                        .foregroundColor(MMColors.textPrimary)
                }
                Text("This Week")
                    .font(MMTypography.caption1Medium)
                    .foregroundColor(MMColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(MMColors.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MMColors.border, lineWidth: 1)
        )
    }

    // MARK: - Level Card

    private var levelCard: some View {
        let level = streakService.userLevel
        let total = streakService.totalMeetings
        let progress: Double = {
            guard let nextThreshold = level.nextThreshold else { return 1.0 }
            let current = Double(total - level.threshold)
            let range = Double(nextThreshold - level.threshold)
            return min(max(current / range, 0), 1.0)
        }()

        return VStack(spacing: 14) {
            HStack {
                Image(systemName: level.icon)
                    .font(.system(size: 20))
                    .foregroundColor(MMColors.primary)
                Text(level.rawValue)
                    .font(MMTypography.headline)
                    .foregroundColor(MMColors.textPrimary)
                Spacer()
                if let next = level.nextLevel {
                    Text("\(total)/\(next.threshold) meetings")
                        .font(MMTypography.caption1Medium)
                        .foregroundColor(MMColors.textSecondary)
                } else {
                    Text("Max level!")
                        .font(MMTypography.caption1Medium)
                        .foregroundColor(MMColors.success)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(MMColors.primaryLight)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [MMColors.primary, MMColors.primaryDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)

            // Level tiers
            HStack(spacing: 0) {
                ForEach([UserLevel.beginner, .active, .powerUser, .meetingMaster], id: \.rawValue) { tier in
                    HStack(spacing: 3) {
                        Image(systemName: tier.icon)
                            .font(.system(size: 10))
                        Text(tier.rawValue)
                            .font(MMTypography.caption2)
                    }
                    .foregroundColor(tier == level ? MMColors.primary : MMColors.textTertiary)
                    if tier != .meetingMaster {
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(MMColors.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MMColors.border, lineWidth: 1)
        )
    }

    // MARK: - Weekly Card

    private var weeklyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("This Week")
                    .font(MMTypography.headline)
                    .foregroundColor(MMColors.textPrimary)
                Spacer()
                Text(weekRangeLabel)
                    .font(MMTypography.caption1)
                    .foregroundColor(MMColors.textTertiary)
            }

            HStack(spacing: 12) {
                statTile(
                    icon: "mic.fill",
                    value: "\(streakService.weeklyMeetings)",
                    label: "Meetings",
                    color: MMColors.primary
                )
                statTile(
                    icon: "checkmark.circle.fill",
                    value: "\(streakService.weeklyActionItems)",
                    label: "Actions Done",
                    color: MMColors.success
                )
                statTile(
                    icon: "list.bullet.circle.fill",
                    value: "\(streakService.weeklyTodosDone)",
                    label: "Todos Done",
                    color: MMColors.info
                )
            }
        }
        .padding(16)
        .background(MMColors.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MMColors.border, lineWidth: 1)
        )
    }

    // MARK: - All-Time Card

    private var allTimeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("All Time")
                .font(MMTypography.headline)
                .foregroundColor(MMColors.textPrimary)

            HStack(spacing: 12) {
                statTile(
                    icon: "waveform",
                    value: "\(streakService.totalMeetings)",
                    label: "Meetings",
                    color: MMColors.primary
                )
                statTile(
                    icon: "checkmark.seal.fill",
                    value: "\(streakService.totalActionItemsCompleted)",
                    label: "Actions Done",
                    color: MMColors.success
                )
                statTile(
                    icon: "flame.fill",
                    value: "\(streakService.longestStreak)",
                    label: "Best Streak",
                    color: MMColors.warning
                )
            }
        }
        .padding(16)
        .background(MMColors.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MMColors.border, lineWidth: 1)
        )
    }

    // MARK: - Stat Tile

    private func statTile(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(MMTypography.title2)
                .foregroundColor(MMColors.textPrimary)

            Text(label)
                .font(MMTypography.caption1)
                .foregroundColor(MMColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(MMColors.cardBgElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private var weekRangeLabel: String {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date,
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
    }
}

#Preview {
    NavigationStack {
        StatsView()
    }
}
