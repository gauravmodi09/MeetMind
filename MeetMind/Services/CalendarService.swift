import Foundation
import EventKit
import Combine

// MARK: - Calendar Event Model

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let organizer: String?
    let attendees: [String]
    let calendarColor: String?
    let isAllDay: Bool

    /// Whether this event is happening right now.
    var isHappeningNow: Bool {
        let now = Date()
        return startDate <= now && endDate > now
    }

    /// How many minutes ago the event started (negative if hasn't started yet).
    var minutesSinceStart: Int {
        Int(Date().timeIntervalSince(startDate) / 60)
    }

    /// Formatted time range, e.g. "10:00 AM - 11:00 AM".
    var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    /// Duration in minutes.
    var durationMinutes: Int {
        Int(endDate.timeIntervalSince(startDate) / 60)
    }

    /// Whether the event hasn't started yet.
    var isUpcoming: Bool {
        startDate > Date()
    }

    /// Whether the event has already ended.
    var isPast: Bool {
        endDate <= Date()
    }
}

// MARK: - Calendar Authorization Status

enum CalendarAuthStatus {
    case notDetermined
    case authorized
    case denied
    case restricted
}

// MARK: - CalendarService

@MainActor
class CalendarService: ObservableObject {
    static let shared = CalendarService()

    // MARK: - Published State

    @Published var authorizationStatus: CalendarAuthStatus = .notDetermined
    @Published var todayEvents: [CalendarEvent] = []
    @Published var upcomingEvents: [CalendarEvent] = []
    @Published var currentEvent: CalendarEvent?
    @Published var isLoading = false

    // MARK: - Private

    private let eventStore = EKEventStore()
    private var refreshTimer: Timer?

    // MARK: - Init

    private init() {
        updateAuthStatus()
    }

    deinit {
        refreshTimer?.invalidate()
    }

    // MARK: - Authorization

    /// Request calendar access from the user.
    func requestAccess() async -> Bool {
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }
            updateAuthStatus()
            if granted {
                await fetchEvents()
                startAutoRefresh()
            }
            return granted
        } catch {
            print("[CalendarService] Access request failed: \(error)")
            updateAuthStatus()
            return false
        }
    }

    private func updateAuthStatus() {
        let status: EKAuthorizationStatus
        if #available(iOS 17.0, *) {
            status = EKEventStore.authorizationStatus(for: .event)
        } else {
            status = EKEventStore.authorizationStatus(for: .event)
        }

        switch status {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .fullAccess, .authorized:
            authorizationStatus = .authorized
        case .denied:
            authorizationStatus = .denied
        case .restricted, .writeOnly:
            authorizationStatus = .restricted
        @unknown default:
            authorizationStatus = .denied
        }
    }

    // MARK: - Fetch Events

    /// Fetch today's events and upcoming events (next 24 hours).
    func fetchEvents() async {
        guard authorizationStatus == .authorized else { return }

        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let now = Date()

        // Today: start of day to end of day
        let todayStart = calendar.startOfDay(for: now)
        guard let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart) else { return }

        // Next 24 hours from now
        guard let next24h = calendar.date(byAdding: .hour, value: 24, to: now) else { return }

        // Fetch today's events
        let todayPredicate = eventStore.predicateForEvents(
            withStart: todayStart,
            end: todayEnd,
            calendars: nil
        )
        let todayEKEvents = eventStore.events(matching: todayPredicate)
        todayEvents = todayEKEvents
            .filter { !$0.isAllDay }
            .map { mapEvent($0) }
            .sorted { $0.startDate < $1.startDate }

        // Fetch upcoming events (next 24h, starting from now)
        let upcomingPredicate = eventStore.predicateForEvents(
            withStart: now,
            end: next24h,
            calendars: nil
        )
        let upcomingEKEvents = eventStore.events(matching: upcomingPredicate)
        upcomingEvents = upcomingEKEvents
            .filter { !$0.isAllDay }
            .map { mapEvent($0) }
            .sorted { $0.startDate < $1.startDate }

        // Detect current event
        currentEvent = todayEvents.first { $0.isHappeningNow }
    }

    // MARK: - Current Meeting Detection

    /// Returns the event happening right now, if any. Useful for auto-suggest recording.
    func detectCurrentMeeting() -> CalendarEvent? {
        return todayEvents.first { $0.isHappeningNow }
    }

    /// Returns all events happening right now (in case of overlapping meetings).
    func detectAllCurrentMeetings() -> [CalendarEvent] {
        return todayEvents.filter { $0.isHappeningNow }
    }

    // MARK: - Match Calendar Events to Recordings

    /// Find the calendar event that best matches a recorded meeting by time overlap.
    /// - Parameters:
    ///   - meetingDate: The start time of the recording.
    ///   - meetingDuration: The duration of the recording in seconds.
    /// - Returns: The best matching calendar event, or nil.
    func matchEvent(toMeetingAt meetingDate: Date, duration: TimeInterval) -> CalendarEvent? {
        let meetingEnd = meetingDate.addingTimeInterval(duration)

        var bestMatch: CalendarEvent?
        var bestOverlap: TimeInterval = 0

        for event in todayEvents {
            let overlap = calculateOverlap(
                start1: event.startDate, end1: event.endDate,
                start2: meetingDate, end2: meetingEnd
            )
            if overlap > bestOverlap {
                bestOverlap = overlap
                bestMatch = event
            }
        }

        // Require at least 2 minutes of overlap to be considered a match
        guard bestOverlap >= 120 else { return nil }
        return bestMatch
    }

    /// Find the calendar event that best matches a Meeting model.
    func matchEvent(toMeeting meeting: Meeting) -> CalendarEvent? {
        return matchEvent(toMeetingAt: meeting.date, duration: meeting.duration)
    }

    // MARK: - Auto Refresh

    /// Start a timer that refreshes events every 60 seconds to keep current-event detection accurate.
    func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchEvents()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Private Helpers

    private func mapEvent(_ ekEvent: EKEvent) -> CalendarEvent {
        let attendeeNames: [String] = ekEvent.attendees?.compactMap { attendee in
            attendee.name ?? attendee.url.absoluteString
        } ?? []

        let organizerName = ekEvent.organizer?.name

        let hexColor: String? = {
            guard let cgColor = ekEvent.calendar.cgColor else { return nil }
            let components = cgColor.components ?? []
            guard components.count >= 3 else { return nil }
            let r = Int(components[0] * 255)
            let g = Int(components[1] * 255)
            let b = Int(components[2] * 255)
            return String(format: "%02X%02X%02X", r, g, b)
        }()

        return CalendarEvent(
            id: ekEvent.eventIdentifier ?? UUID().uuidString,
            title: ekEvent.title ?? "Untitled Event",
            startDate: ekEvent.startDate,
            endDate: ekEvent.endDate,
            location: ekEvent.location,
            organizer: organizerName,
            attendees: attendeeNames,
            calendarColor: hexColor,
            isAllDay: ekEvent.isAllDay
        )
    }

    private func calculateOverlap(
        start1: Date, end1: Date,
        start2: Date, end2: Date
    ) -> TimeInterval {
        let overlapStart = max(start1, start2)
        let overlapEnd = min(end1, end2)
        return max(0, overlapEnd.timeIntervalSince(overlapStart))
    }
}

// autoStartRecording is already defined in MainTabView.swift
