#if os(macOS)
import SwiftUI

enum MacSection: String, CaseIterable, Identifiable {
    case meetings
    case todos
    case actionItems
    case notes
    case people
    case library
    case search
    case chat
    case recipes
    case settings

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .meetings:    return "waveform.circle.fill"
        case .todos:       return "checkmark.circle.fill"
        case .actionItems: return "list.bullet.circle.fill"
        case .notes:       return "note.text"
        case .people:      return "person.2.fill"
        case .library:     return "books.vertical.fill"
        case .search:      return "magnifyingglass"
        case .chat:        return "bubble.left.and.bubble.right.fill"
        case .recipes:     return "sparkle"
        case .settings:    return "gearshape.fill"
        }
    }

    var label: String {
        switch self {
        case .meetings:    return "Meetings"
        case .todos:       return "Todos"
        case .actionItems: return "Action Items"
        case .notes:       return "Notes"
        case .people:      return "People"
        case .library:     return "Library"
        case .search:      return "Search"
        case .chat:        return "AI Chat"
        case .recipes:     return "Recipes"
        case .settings:    return "Settings"
        }
    }

    var subtitle: String {
        switch self {
        case .meetings:    return "Recordings & briefs"
        case .todos:       return "Tasks & action items"
        case .actionItems: return "Cross-meeting items"
        case .notes:       return "Meeting notes"
        case .people:      return "Contacts & participants"
        case .library:     return "Clients & insights"
        case .search:      return "Find anything"
        case .chat:        return "Ask your meetings"
        case .recipes:     return "AI templates"
        case .settings:    return "Preferences"
        }
    }

    /// Sections shown in main nav (not settings)
    static var mainSections: [MacSection] {
        [.meetings, .todos, .actionItems, .notes, .people, .library, .search, .chat, .recipes]
    }
}

struct MacSidebar: View {
    @Binding var activeSection: MacSection
    @EnvironmentObject var meetingService: MeetingService
    var isRecording: Bool = false
    var onStartRecording: () -> Void = {}

    private let sidebarWidth: CGFloat = 220

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App header
            appHeader
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)

            // New recording button
            newRecordingButton
                .padding(.horizontal, 14)
                .padding(.bottom, 16)

            // Navigation - scrollable for more items
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 2) {
                    // Primary nav
                    sidebarGroup("MAIN") {
                        sidebarItem(for: .meetings)
                        sidebarItem(for: .todos)
                        sidebarItem(for: .actionItems)
                        sidebarItem(for: .notes)
                    }

                    sidebarGroup("INTELLIGENCE") {
                        sidebarItem(for: .chat)
                        sidebarItem(for: .recipes)
                        sidebarItem(for: .search)
                    }

                    sidebarGroup("EXPLORE") {
                        sidebarItem(for: .people)
                        sidebarItem(for: .library)
                    }
                }
                .padding(.horizontal, 10)
            }

            Spacer()

            // Recording indicator
            if isRecording {
                recordingIndicator
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
            }

            // Stats summary
            statsSummary
                .padding(.horizontal, 14)
                .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 14)
                .padding(.bottom, 8)

            // Settings at bottom
            sidebarItem(for: .settings)
                .padding(.horizontal, 10)
                .padding(.bottom, 14)
        }
        .frame(width: sidebarWidth)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - App Header

    private var appHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [MMColors.primary, MMColors.primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("MeetMind")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(MMColors.textPrimary)
                Text("Meeting Intelligence")
                    .font(.system(size: 10))
                    .foregroundColor(MMColors.textTertiary)
            }
        }
    }

    // MARK: - New Recording Button

    private var newRecordingButton: some View {
        Button {
            onStartRecording()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("New Recording")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(MMColors.primary)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sidebar Group

    private func sidebarGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(MMColors.textTertiary)
                .tracking(0.8)
                .padding(.horizontal, 10)
                .padding(.top, 12)
                .padding(.bottom, 4)
            content()
        }
    }

    // MARK: - Sidebar Item

    private func sidebarItem(for section: MacSection) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                activeSection = section
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                    .font(.system(size: 13))
                    .foregroundColor(activeSection == section ? MMColors.primary : MMColors.textSecondary)
                    .frame(width: 20)

                Text(section.label)
                    .font(.system(size: 13, weight: activeSection == section ? .semibold : .regular))
                    .foregroundColor(activeSection == section ? MMColors.textPrimary : MMColors.textSecondary)

                Spacer()

                // Badge for pending items
                if section == .todos, pendingTodoCount > 0 {
                    Text("\(pendingTodoCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(MMColors.primary))
                }

                if section == .actionItems, pendingActionCount > 0 {
                    Text("\(pendingActionCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(MMColors.warning))
                }

                if section == .meetings, meetingService.processingState != .idle {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(activeSection == section ? MMColors.primary.opacity(0.08) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recording Indicator

    private var recordingIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 16, height: 16)
                )
            Text("Recording...")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.red)
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.15)))
        )
    }

    // MARK: - Stats Summary

    private var statsSummary: some View {
        HStack(spacing: 0) {
            statItem(value: "\(meetingService.meetings.count)", label: "Meetings")
            Spacer()
            statItem(value: "\(totalActionItems)", label: "Actions")
            Spacer()
            statItem(value: formattedTotalTime, label: "Recorded")
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(MMColors.background)
        )
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(MMColors.textPrimary)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(MMColors.textTertiary)
        }
    }

    // MARK: - Computed

    private var pendingTodoCount: Int {
        TodoService.shared.todos.filter { !$0.isCompleted }.count
    }

    private var pendingActionCount: Int {
        meetingService.meetings.reduce(0) { $0 + $1.briefActionItems.filter { !$0.isCompleted }.count }
    }

    private var totalActionItems: Int {
        meetingService.meetings.reduce(0) { $0 + $1.briefActionItems.count }
    }

    private var formattedTotalTime: String {
        let totalMinutes = Int(meetingService.meetings.reduce(0) { $0 + $1.duration }) / 60
        if totalMinutes < 60 { return "\(totalMinutes)m" }
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }
}

// Keep backward compatibility alias
typealias MacIconRail = MacSidebar
#endif
