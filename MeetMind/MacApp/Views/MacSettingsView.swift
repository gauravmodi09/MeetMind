#if os(macOS)
import SwiftUI

struct MacSettingsView: View {
    @AppStorage("groqAPIKey") private var apiKey = ""
    @AppStorage("defaultAudioSource") private var defaultAudioSource = "system"
    @AppStorage("recordingQuality") private var recordingQuality = "high"
    @AppStorage("autoDetectMeetings") private var autoDetectMeetings = true
    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(MMColors.textPrimary)
                    Text("Configure MeetMind for your workflow")
                        .font(.system(size: 13))
                        .foregroundColor(MMColors.textTertiary)
                }

                // AI & Processing
                settingsSection("AI & Processing", icon: "cpu") {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Groq API Key")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(MMColors.textSecondary)
                            SecureField("Enter your Groq API key", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 13))
                            Text("Used for meeting transcription and AI briefs. Get a key at console.groq.com")
                                .font(.system(size: 11))
                                .foregroundColor(MMColors.textTertiary)
                        }
                    }
                }

                // Recording
                settingsSection("Recording", icon: "mic.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Default Audio Source")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(MMColors.textSecondary)
                            Picker("", selection: $defaultAudioSource) {
                                Text("System Audio").tag("system")
                                Text("Microphone").tag("microphone")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 240)
                            Text("System Audio captures meeting apps (Zoom, Teams, etc). Microphone uses your Mac's built-in mic.")
                                .font(.system(size: 11))
                                .foregroundColor(MMColors.textTertiary)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Recording Quality")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(MMColors.textSecondary)
                            Picker("", selection: $recordingQuality) {
                                Text("Standard (16 kHz)").tag("standard")
                                Text("High (44.1 kHz)").tag("high")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 280)
                        }

                        Toggle(isOn: $autoDetectMeetings) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto-detect meeting apps")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(MMColors.textSecondary)
                                Text("Automatically detect when Zoom, Teams, Meet, or other apps are active")
                                    .font(.system(size: 11))
                                    .foregroundColor(MMColors.textTertiary)
                            }
                        }
                        .toggleStyle(.switch)
                    }
                }

                // App
                settingsSection("App", icon: "gearshape") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $showMenuBarExtra) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Show in menu bar")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(MMColors.textSecondary)
                                Text("Quick access to recording and recent meetings from the menu bar")
                                    .font(.system(size: 11))
                                    .foregroundColor(MMColors.textTertiary)
                            }
                        }
                        .toggleStyle(.switch)
                    }
                }

                // About
                settingsSection("About", icon: "info.circle") {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [MMColors.primary, MMColors.primary.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("MeetMind for Mac")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(MMColors.textPrimary)
                            Text("Version 1.0 · AI-Powered Meeting Intelligence")
                                .font(.system(size: 12))
                                .foregroundColor(MMColors.textTertiary)
                        }
                    }
                }
            }
            .padding(28)
        }
        .background(MMColors.backgroundElevated)
    }

    private func settingsSection<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(MMColors.primary)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MMColors.textPrimary)
            }
            content()
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(MMColors.background)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(MMColors.border))
                )
        }
    }
}
#endif
