import SwiftUI
import EventKit

struct UpcomingMeetingsView: View {
    @StateObject private var calendarService = CalendarService.shared
    @State private var showPermissionAlert = false
    @State private var cardsAppeared = false

    /// Called when user taps "Record" on an event.
    var onRecordTapped: ((CalendarEvent) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            switch calendarService.authorizationStatus {
            case .notDetermined:
                permissionRequestCard
            case .denied, .restricted:
                permissionDeniedCard
            case .authorized:
                if calendarService.isLoading && calendarService.todayEvents.isEmpty {
                    loadingState
                } else if calendarService.todayEvents.isEmpty {
                    emptyState
                } else {
                    calendarContent
                }
            }
        }
        .task {
            if calendarService.authorizationStatus == .notDetermined {
                _ = await calendarService.requestAccess()
            } else if calendarService.authorizationStatus == .authorized {
                await calendarService.fetchEvents()
                calendarService.startAutoRefresh()
            }
        }
    }

    // MARK: - Live Meeting Banner

    @ViewBuilder
    private var liveMeetingBanner: some View {
        if let current = calendarService.currentEvent {
            let minutes = current.minutesSinceStart

            Button {
                onRecordTapped?(current)
            } label: {
                HStack(spacing: 12) {
                    // Pulsing red dot
                    ZStack {
                        Circle()
                            .fill(MMColors.recording.opacity(0.3))
                            .frame(width: 32, height: 32)

                        Circle()
                            .fill(MMColors.recording)
                            .frame(width: 12, height: 12)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(current.title)
                            .font(MMTypography.subheadlineMedium)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(bannerSubtitle(minutes: minutes))
                            .font(MMTypography.caption1)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Record")
                            .font(MMTypography.caption1Medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [MMColors.recording, MMColors.recording.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(MMColors.recording.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func bannerSubtitle(minutes: Int) -> String {
        if minutes <= 0 {
            return "Starting now -- tap to record"
        } else if minutes == 1 {
            return "Started 1 min ago -- tap to record"
        } else {
            return "Started \(minutes) min ago -- tap to record"
        }
    }

    // MARK: - Calendar Content

    private var calendarContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Live meeting banner
            liveMeetingBanner
                .padding(.horizontal, 16)

            // Section header
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MMColors.primary)

                Text("Today's Calendar")
                    .font(MMTypography.headline)
                    .foregroundColor(MMColors.textPrimary)

                Spacer()

                Text("\(calendarService.todayEvents.count) event\(calendarService.todayEvents.count == 1 ? "" : "s")")
                    .font(MMTypography.caption1)
                    .foregroundColor(MMColors.textTertiary)
            }
            .padding(.horizontal, 16)

            // Events list
            LazyVStack(spacing: 8) {
                ForEach(Array(calendarService.todayEvents.enumerated()), id: \.element.id) { index, event in
                    CalendarEventCard(event: event, onRecord: {
                        onRecordTapped?(event)
                    })
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 16)
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.8)
                            .delay(Double(index) * 0.07),
                        value: cardsAppeared
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .onAppear {
            withAnimation {
                cardsAppeared = true
            }
        }
    }

    // MARK: - Permission Request Card

    private var permissionRequestCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(MMColors.primary)

            VStack(spacing: 6) {
                Text("See your schedule")
                    .font(MMTypography.headline)
                    .foregroundColor(MMColors.textPrimary)

                Text("Connect your calendar to see upcoming meetings and start recording with one tap.")
                    .font(MMTypography.footnote)
                    .foregroundColor(MMColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 260)
            }

            Button {
                Task {
                    _ = await calendarService.requestAccess()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13, weight: .medium))
                    Text("Connect Calendar")
                        .font(MMTypography.subheadlineMedium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(MMColors.primary)
                )
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(MMColors.cardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MMColors.border, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Permission Denied

    private var permissionDeniedCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(MMColors.warning)

            Text("Calendar access denied")
                .font(MMTypography.subheadlineMedium)
                .foregroundColor(MMColors.textPrimary)

            Text("Enable calendar access in Settings to see your upcoming meetings here.")
                .font(MMTypography.caption1)
                .foregroundColor(MMColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 240)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(MMTypography.caption1Medium)
                    .foregroundColor(MMColors.primary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(MMColors.cardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MMColors.border, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(MMColors.textTertiary)

            Text("No meetings today")
                .font(MMTypography.subheadlineMedium)
                .foregroundColor(MMColors.textSecondary)

            Text("Your calendar is clear. Enjoy the focus time!")
                .font(MMTypography.caption1)
                .foregroundColor(MMColors.textTertiary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(MMColors.cardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MMColors.border, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(MMColors.primary)

            Text("Loading calendar...")
                .font(MMTypography.caption1)
                .foregroundColor(MMColors.textTertiary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(MMColors.cardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MMColors.border, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Calendar Event Card

private struct CalendarEventCard: View {
    let event: CalendarEvent
    let onRecord: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Color accent bar
            Rectangle()
                .fill(accentColor)
                .frame(width: 4)

            HStack(spacing: 12) {
                // Time column
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedStart)
                        .font(MMTypography.caption1Medium)
                        .foregroundColor(event.isHappeningNow ? MMColors.recording : MMColors.textPrimary)

                    Text(formattedEnd)
                        .font(MMTypography.caption2)
                        .foregroundColor(MMColors.textTertiary)

                    Text("\(event.durationMinutes)m")
                        .font(MMTypography.caption2)
                        .foregroundColor(MMColors.textTertiary)
                }
                .frame(width: 56, alignment: .leading)

                // Divider
                Rectangle()
                    .fill(MMColors.divider)
                    .frame(width: 1, height: 36)

                // Event info
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        if event.isHappeningNow {
                            Text("LIVE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(MMColors.recording)
                                )
                        }

                        Text(event.title)
                            .font(MMTypography.subheadlineMedium)
                            .foregroundColor(MMColors.textPrimary)
                            .lineLimit(1)
                    }

                    if let location = event.location, !location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 9))
                            Text(location)
                                .font(MMTypography.caption2)
                        }
                        .foregroundColor(MMColors.textTertiary)
                        .lineLimit(1)
                    }

                    if !event.attendees.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 9))
                            Text("\(event.attendees.count) attendee\(event.attendees.count == 1 ? "" : "s")")
                                .font(MMTypography.caption2)
                        }
                        .foregroundColor(MMColors.textTertiary)
                    }
                }

                Spacer()

                // Record button
                if !event.isPast {
                    Button(action: onRecord) {
                        HStack(spacing: 4) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 11, weight: .medium))
                            Text(event.isHappeningNow ? "Record" : "Record")
                                .font(MMTypography.caption1Medium)
                        }
                        .foregroundColor(event.isHappeningNow ? .white : MMColors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(event.isHappeningNow
                                      ? MMColors.primary
                                      : MMColors.primaryLight)
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Done")
                        .font(MMTypography.caption1)
                        .foregroundColor(MMColors.textTertiary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(MMColors.cardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(event.isHappeningNow ? MMColors.recording.opacity(0.3) : MMColors.border, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private var accentColor: Color {
        if event.isHappeningNow {
            return MMColors.recording
        } else if let hex = event.calendarColor {
            return Color(hex: hex)
        } else {
            return MMColors.primary
        }
    }

    private var formattedStart: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: event.startDate)
    }

    private var formattedEnd: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: event.endDate)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        UpcomingMeetingsView()
    }
    .background(MMColors.background)
}
