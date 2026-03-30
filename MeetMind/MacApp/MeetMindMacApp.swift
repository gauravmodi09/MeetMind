#if os(macOS)
import SwiftUI

@main
struct MeetMindMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var meetingService = MeetingService.shared

    var body: some Scene {
        // Menu bar extra
        MenuBarExtra("MeetMind", systemImage: "waveform.circle.fill") {
            MenuBarView()
                .environmentObject(meetingService)
        }
        .menuBarExtraStyle(.window)

        // Main window
        WindowGroup {
            MacMainView()
                .environmentObject(meetingService)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 600)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[MeetMind Mac] App launched")
        MeetingAppDetector.shared.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        MeetingAppDetector.shared.stopMonitoring()
    }
}
#endif
