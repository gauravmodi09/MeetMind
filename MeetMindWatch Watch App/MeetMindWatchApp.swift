import SwiftUI

@main
struct MeetMindWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}

struct WatchHomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Record button
                    Button {
                        // Opens iOS app via deep link
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.2))
                                    .frame(width: 70, height: 70)
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.purple)
                            }
                            Text("Record")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .buttonStyle(.plain)

                    // Quick stats
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("0")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.purple)
                            Text("Meetings")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        VStack(spacing: 4) {
                            Text("0")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.cyan)
                            Text("Tasks")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("MeetMind")
        }
    }
}
