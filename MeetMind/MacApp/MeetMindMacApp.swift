#if os(macOS)
import SwiftUI
import AppKit

@main
struct MeetMindMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var meetingService = MeetingService.shared

    var body: some Scene {
        // Main window
        WindowGroup {
            MacMainView()
                .environmentObject(meetingService)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 600)

        // Menu bar extra
        MenuBarExtra("MeetMind", systemImage: "waveform.circle.fill") {
            MenuBarView()
                .environmentObject(meetingService)
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[MeetMind Mac] App launched")
        MeetingAppDetector.shared.startMonitoring()

        // Ensure the main window opens on launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if NSApplication.shared.windows.filter({ $0.isVisible }).isEmpty {
                NSApplication.shared.activate(ignoringOtherApps: true)
                if let window = NSApplication.shared.windows.first(where: { $0.canBecomeMain }) {
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        MeetingAppDetector.shared.stopMonitoring()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // Re-open main window when clicking Dock icon with no visible windows
            for window in sender.windows {
                if window.canBecomeMain {
                    window.makeKeyAndOrderFront(nil)
                    return true
                }
            }
        }
        return true
    }
}
#endif
