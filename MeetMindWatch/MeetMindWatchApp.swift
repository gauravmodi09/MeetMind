import SwiftUI
import WidgetKit

@main
struct MeetMindWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}

// MARK: - Watch Home View

struct WatchHomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Record button
                    Button {
                        // Opens iOS app via WatchConnectivity
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.purple)
                            }
                            Text("Record Meeting")
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                    .buttonStyle(.plain)

                    // Stats
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("0")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.purple)
                            Text("Meetings")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        VStack(spacing: 4) {
                            Text("0")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.cyan)
                            Text("Tasks")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("MeetMind")
        }
    }
}
