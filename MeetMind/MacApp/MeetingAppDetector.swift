#if os(macOS)
import AppKit
import Combine

@MainActor
class MeetingAppDetector: ObservableObject {
    static let shared = MeetingAppDetector()

    @Published var activeMeetingApp: MeetingApp?
    @Published var isInMeeting = false

    private var cancellables = Set<AnyCancellable>()
    private var pollTimer: Timer?

    enum MeetingApp: String, CaseIterable {
        case zoom = "us.zoom.xos"
        case teams = "com.microsoft.teams2"
        case meet = "com.google.Chrome"  // Google Meet runs in browser
        case slack = "com.tinyspeck.slackmacgap"
        case webex = "com.webex.meetingmanager"
        case facetime = "com.apple.FaceTime"

        var displayName: String {
            switch self {
            case .zoom: return "Zoom"
            case .teams: return "Microsoft Teams"
            case .meet: return "Google Meet"
            case .slack: return "Slack Huddle"
            case .webex: return "Webex"
            case .facetime: return "FaceTime"
            }
        }

        var icon: String {
            switch self {
            case .zoom: return "video.fill"
            case .teams: return "person.3.fill"
            case .meet: return "globe"
            case .slack: return "number"
            case .webex: return "video.fill"
            case .facetime: return "phone.fill"
            }
        }
    }

    func startMonitoring() {
        // Watch for app activations
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] app in
                self?.checkApp(app)
            }
            .store(in: &cancellables)

        // Also poll running apps periodically for meeting detection
        pollTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollRunningApps()
            }
        }

        // Initial check
        pollRunningApps()
    }

    func stopMonitoring() {
        cancellables.removeAll()
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func checkApp(_ app: NSRunningApplication) {
        guard let bundleId = app.bundleIdentifier else { return }
        if let meetingApp = MeetingApp.allCases.first(where: { $0.rawValue == bundleId }) {
            activeMeetingApp = meetingApp
        }
    }

    private func pollRunningApps() {
        let runningApps = NSWorkspace.shared.runningApplications
        let meetingBundleIds = Set(MeetingApp.allCases.map(\.rawValue))

        let activeMeetingApps = runningApps.filter { app in
            guard let bundleId = app.bundleIdentifier else { return false }
            return meetingBundleIds.contains(bundleId) && !app.isTerminated
        }

        if let first = activeMeetingApps.first,
           let bundleId = first.bundleIdentifier,
           let app = MeetingApp.allCases.first(where: { $0.rawValue == bundleId }) {
            activeMeetingApp = app
            isInMeeting = true
        } else {
            activeMeetingApp = nil
            isInMeeting = false
        }
    }
}
#endif
