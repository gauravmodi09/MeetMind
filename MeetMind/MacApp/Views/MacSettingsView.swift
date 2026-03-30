#if os(macOS)
import SwiftUI

struct MacSettingsView: View {
    @AppStorage("groqAPIKey") private var apiKey = ""
    @AppStorage("defaultAudioSource") private var defaultAudioSource = "system"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Settings")
                    .font(.system(size: 20, weight: .bold))

                settingsSection("AI & Processing") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Groq API Key")
                            .font(.system(size: 12, weight: .medium))
                        SecureField("Enter your Groq API key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                    }
                }

                settingsSection("Recording") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default Audio Source")
                            .font(.system(size: 12, weight: .medium))
                        Picker("", selection: $defaultAudioSource) {
                            Text("System Audio").tag("system")
                            Text("Microphone").tag("microphone")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 240)

                        Text("System Audio captures meeting apps (Zoom, Teams, etc). Microphone uses your Mac's built-in mic.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                settingsSection("About") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MeetMind for Mac")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Version 1.0")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(24)
        }
        .background(Color.white)
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.180))
            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 0.98, green: 0.98, blue: 0.98)))
        }
    }
}
#endif
