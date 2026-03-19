import Foundation
import Combine

/// Tracks meeting recording streaks, totals, and weekly productivity stats.
/// Persists all data in UserDefaults.
@MainActor
class StreakService: ObservableObject {
    static let shared = StreakService()

    // MARK: - Keys

    private enum Keys {
        static let currentStreak = "streak_current"
        static let longestStreak = "streak_longest"
        static let lastRecordingDate = "streak_lastRecordingDate"
        static let totalMeetings = "streak_totalMeetings"
        static let totalActionItemsCompleted = "streak_totalActionItemsCompleted"
        static let weeklyMeetings = "streak_weeklyMeetings"
        static let weeklyActionItems = "streak_weeklyActionItems"
        static let weeklyTodosDone = "streak_weeklyTodosDone"
        static let weekStartDate = "streak_weekStartDate"
    }

    // MARK: - Published State

    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var totalMeetings: Int = 0
    @Published var totalActionItemsCompleted: Int = 0
    @Published var weeklyMeetings: Int = 0
    @Published var weeklyActionItems: Int = 0
    @Published var weeklyTodosDone: Int = 0
    @Published var productivityScore: Int = 0

    // MARK: - Dependencies

    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    private init() {
        loadFromDefaults()
        resetWeekIfNeeded()
        recalculateProductivityScore()

        // Listen for meeting list changes
        MeetingService.shared.$meetings
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncFromMeetingService()
            }
            .store(in: &cancellables)

        // Listen for todo completions
        TodoService.shared.$todos
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncTodoCompletions()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public API

    /// Call after a meeting is recorded or completed to update the streak.
    func updateStreak() {
        let today = calendar.startOfDay(for: Date())

        if let lastDate = defaults.object(forKey: Keys.lastRecordingDate) as? Date {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysBetween == 0 {
                // Already recorded today — no streak change
            } else if daysBetween == 1 {
                // Consecutive day — extend streak
                currentStreak += 1
            } else {
                // Streak broken — reset to 1
                currentStreak = 1
            }
        } else {
            // First ever recording
            currentStreak = 1
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        defaults.set(today, forKey: Keys.lastRecordingDate)
        saveToDefaults()
    }

    /// Returns the current streak count.
    func getCurrentStreak() -> Int {
        // Verify streak is still valid (hasn't expired since last check)
        guard let lastDate = defaults.object(forKey: Keys.lastRecordingDate) as? Date else {
            return 0
        }

        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastDate)
        let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

        if daysBetween > 1 {
            // Streak has expired
            currentStreak = 0
            saveToDefaults()
        }

        return currentStreak
    }

    /// Returns weekly stats: meetings, action items completed, todos done, productivity score.
    func getWeeklyStats() -> WeeklyStats {
        resetWeekIfNeeded()
        return WeeklyStats(
            meetings: weeklyMeetings,
            actionItemsCompleted: weeklyActionItems,
            todosDone: weeklyTodosDone,
            productivityScore: productivityScore
        )
    }

    /// Increment action items completed count (call when an action item is toggled complete).
    func recordActionItemCompleted() {
        resetWeekIfNeeded()
        totalActionItemsCompleted += 1
        weeklyActionItems += 1
        recalculateProductivityScore()
        saveToDefaults()
    }

    /// Decrement action items completed count (call when an action item is unchecked).
    func recordActionItemUncompleted() {
        resetWeekIfNeeded()
        if totalActionItemsCompleted > 0 { totalActionItemsCompleted -= 1 }
        if weeklyActionItems > 0 { weeklyActionItems -= 1 }
        recalculateProductivityScore()
        saveToDefaults()
    }

    /// Increment weekly todo done count.
    func recordTodoCompleted() {
        resetWeekIfNeeded()
        weeklyTodosDone += 1
        recalculateProductivityScore()
        saveToDefaults()
    }

    /// Decrement weekly todo done count.
    func recordTodoUncompleted() {
        resetWeekIfNeeded()
        if weeklyTodosDone > 0 { weeklyTodosDone -= 1 }
        recalculateProductivityScore()
        saveToDefaults()
    }

    /// User level based on total meetings recorded.
    var userLevel: UserLevel {
        UserLevel.from(totalMeetings: totalMeetings)
    }

    // MARK: - Sync from Services

    /// Recalculate totals from MeetingService (source of truth for meetings).
    private func syncFromMeetingService() {
        let meetings = MeetingService.shared.meetings
        let completedMeetings = meetings.filter { $0.status == .complete }

        let newTotal = completedMeetings.count
        let previousTotal = totalMeetings

        // Update total
        totalMeetings = newTotal

        // Count meetings this week
        resetWeekIfNeeded()
        let weekStart = currentWeekStart()
        weeklyMeetings = completedMeetings.filter { $0.date >= weekStart }.count

        // Count completed action items across all meetings
        let completedActions = meetings.flatMap { $0.briefActionItems }.filter { $0.isCompleted }.count
        totalActionItemsCompleted = completedActions
        weeklyActionItems = meetings
            .filter { $0.date >= weekStart }
            .flatMap { $0.briefActionItems }
            .filter { $0.isCompleted }
            .count

        // If new meetings were added, update the streak
        if newTotal > previousTotal {
            updateStreak()
        }

        recalculateProductivityScore()
        saveToDefaults()
    }

    /// Sync todo completion counts from TodoService.
    private func syncTodoCompletions() {
        let todos = TodoService.shared.todos
        let weekStart = currentWeekStart()

        weeklyTodosDone = todos.filter {
            $0.isCompleted && ($0.completedAt ?? $0.createdAt) >= weekStart
        }.count

        recalculateProductivityScore()
        saveToDefaults()
    }

    // MARK: - Week Management

    private func currentWeekStart() -> Date {
        calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: Date()).date ?? Date()
    }

    private func resetWeekIfNeeded() {
        let weekStart = currentWeekStart()

        if let storedStart = defaults.object(forKey: Keys.weekStartDate) as? Date {
            if !calendar.isDate(storedStart, inSameDayAs: weekStart) {
                // New week — reset weekly counters
                weeklyMeetings = 0
                weeklyActionItems = 0
                weeklyTodosDone = 0
                defaults.set(weekStart, forKey: Keys.weekStartDate)
                saveToDefaults()
            }
        } else {
            defaults.set(weekStart, forKey: Keys.weekStartDate)
        }
    }

    private func recalculateProductivityScore() {
        productivityScore = weeklyMeetings + weeklyActionItems + weeklyTodosDone
    }

    // MARK: - Persistence

    private func loadFromDefaults() {
        currentStreak = defaults.integer(forKey: Keys.currentStreak)
        longestStreak = defaults.integer(forKey: Keys.longestStreak)
        totalMeetings = defaults.integer(forKey: Keys.totalMeetings)
        totalActionItemsCompleted = defaults.integer(forKey: Keys.totalActionItemsCompleted)
        weeklyMeetings = defaults.integer(forKey: Keys.weeklyMeetings)
        weeklyActionItems = defaults.integer(forKey: Keys.weeklyActionItems)
        weeklyTodosDone = defaults.integer(forKey: Keys.weeklyTodosDone)
    }

    private func saveToDefaults() {
        defaults.set(currentStreak, forKey: Keys.currentStreak)
        defaults.set(longestStreak, forKey: Keys.longestStreak)
        defaults.set(totalMeetings, forKey: Keys.totalMeetings)
        defaults.set(totalActionItemsCompleted, forKey: Keys.totalActionItemsCompleted)
        defaults.set(weeklyMeetings, forKey: Keys.weeklyMeetings)
        defaults.set(weeklyActionItems, forKey: Keys.weeklyActionItems)
        defaults.set(weeklyTodosDone, forKey: Keys.weeklyTodosDone)
    }
}

// MARK: - Supporting Types

struct WeeklyStats {
    let meetings: Int
    let actionItemsCompleted: Int
    let todosDone: Int
    let productivityScore: Int
}

enum UserLevel: String {
    case beginner = "Beginner"
    case active = "Active"
    case powerUser = "Power User"
    case meetingMaster = "Meeting Master"

    var icon: String {
        switch self {
        case .beginner:      return "leaf"
        case .active:        return "bolt"
        case .powerUser:     return "star"
        case .meetingMaster: return "crown"
        }
    }

    var threshold: Int {
        switch self {
        case .beginner:      return 0
        case .active:        return 11
        case .powerUser:     return 51
        case .meetingMaster: return 101
        }
    }

    var nextLevel: UserLevel? {
        switch self {
        case .beginner:      return .active
        case .active:        return .powerUser
        case .powerUser:     return .meetingMaster
        case .meetingMaster: return nil
        }
    }

    var nextThreshold: Int? {
        nextLevel?.threshold
    }

    static func from(totalMeetings: Int) -> UserLevel {
        if totalMeetings > 100 { return .meetingMaster }
        if totalMeetings > 50  { return .powerUser }
        if totalMeetings > 10  { return .active }
        return .beginner
    }
}
