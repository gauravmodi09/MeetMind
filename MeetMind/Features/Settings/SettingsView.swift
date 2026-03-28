import SwiftUI
import CoreData

struct SettingsView: View {
    @AppStorage("groqAPIKey") private var apiKey = ""
    @AppStorage("geminiAPIKey") private var geminiAPIKey = ""
    @AppStorage("recordingQuality") private var recordingQuality = RecordingQuality.standard.rawValue
    @AppStorage("aiPromptStyle") private var aiPromptStyle = AIPromptStyle.concise.rawValue
    @AppStorage("audioRetention") private var audioRetention = AudioRetention.fourteenDays.rawValue
    @AppStorage("autoDeleteAudioAfterProcessing") private var autoDeleteAudio = true
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false
    @AppStorage("teamsWebhookURL") private var teamsWebhookURL = ""
    @AppStorage("appTheme") private var appTheme = "system"

    @EnvironmentObject var authService: AuthService

    @StateObject private var storageService = StorageManagementService.shared
    @StateObject private var analytics = AnalyticsService.shared

    @State private var isEditingAPIKey = false
    @State private var apiKeyDraft = ""
    @State private var isEditingGeminiKey = false
    @State private var geminiKeyDraft = ""
    @State private var showExportSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showCleanupConfirmation = false
    @State private var showICloudAlert = false
    @State private var exportURLs: [URL] = []
    @State private var showSignOutConfirmation = false

    private var maskedKey: String {
        guard apiKey.count > 8 else { return String(repeating: "\u{2022}", count: max(apiKey.count, 8)) }
        let prefix = String(apiKey.prefix(4))
        let suffix = String(apiKey.suffix(4))
        return "\(prefix)\(String(repeating: "\u{2022}", count: 8))\(suffix)"
    }

    private var maskedGeminiKey: String {
        guard geminiAPIKey.count > 8 else { return String(repeating: "\u{2022}", count: max(geminiAPIKey.count, 8)) }
        let prefix = String(geminiAPIKey.prefix(4))
        let suffix = String(geminiAPIKey.suffix(4))
        return "\(prefix)\(String(repeating: "\u{2022}", count: 8))\(suffix)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Account
                    settingsSection(header: "ACCOUNT") {
                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                if let photoURL = authService.photoURL {
                                    AsyncImage(url: photoURL) { image in
                                        image.resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Circle().fill(MMColors.primary.opacity(0.2))
                                    }
                                    .frame(width: 44, height: 44)
                                    .clipShape(Circle())
                                } else {
                                    ZStack {
                                        Circle().fill(MMColors.primary.opacity(0.2))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "person.fill")
                                            .foregroundColor(MMColors.primary)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(authService.displayName)
                                        .font(MMTypography.bodyMedium)
                                        .foregroundColor(MMColors.textPrimary)
                                    if !authService.email.isEmpty {
                                        Text(authService.email)
                                            .font(MMTypography.caption1)
                                            .foregroundColor(MMColors.textSecondary)
                                    }
                                    Text(authService.userProfile.role.displayName)
                                        .font(MMTypography.caption1)
                                        .foregroundColor(MMColors.primary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            sectionDivider

                            Button {
                                showSignOutConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .foregroundColor(MMColors.recording)
                                    Text("Sign Out")
                                        .font(MMTypography.bodyMedium)
                                        .foregroundColor(MMColors.recording)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                        }
                    }

                    // MARK: - AI Configuration
                    settingsSection(header: "AI CONFIGURATION") {
                        VStack(spacing: 0) {
                            // API Key row
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Groq API Key")
                                        .font(MMTypography.bodyMedium)
                                        .foregroundColor(MMColors.textPrimary)
                                    Text(apiKey.isEmpty ? "Not configured" : maskedKey)
                                        .font(MMTypography.monoSmall)
                                        .foregroundColor(apiKey.isEmpty ? MMColors.recording : MMColors.textSecondary)
                                }
                                Spacer()
                                Button {
                                    apiKeyDraft = apiKey
                                    isEditingAPIKey = true
                                } label: {
                                    Text("Edit")
                                        .font(MMTypography.footnoteMedium)
                                        .foregroundColor(MMColors.primary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            sectionDivider

                            // Gemini API Key row
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Gemini API Key")
                                        .font(MMTypography.bodyMedium)
                                        .foregroundColor(MMColors.textPrimary)
                                    Text(geminiAPIKey.isEmpty ? "Not configured" : maskedGeminiKey)
                                        .font(MMTypography.monoSmall)
                                        .foregroundColor(geminiAPIKey.isEmpty ? MMColors.warning : MMColors.textSecondary)
                                }
                                Spacer()
                                Button {
                                    geminiKeyDraft = geminiAPIKey
                                    isEditingGeminiKey = true
                                } label: {
                                    Text("Edit")
                                        .font(MMTypography.footnoteMedium)
                                        .foregroundColor(MMColors.primary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            sectionDivider

                            Text("Your keys are stored locally on this device.")
                                .font(MMTypography.caption1)
                                .foregroundColor(MMColors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                        }
                    }

                    // MARK: - Calendar Integration
                    settingsSection(header: "CALENDAR INTEGRATION") {
                        VStack(spacing: 0) {
                            // Google Calendar
                            Button {
                                // Open iPhone Settings to add Google account
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue.opacity(0.12))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "g.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.blue)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Google Calendar")
                                            .font(MMTypography.bodyMedium)
                                            .foregroundColor(MMColors.textPrimary)
                                        Text("Add Google account in iPhone Settings to sync")
                                            .font(MMTypography.caption1)
                                            .foregroundColor(MMColors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(MMColors.textTertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }

                            sectionDivider

                            // Outlook Calendar
                            Button {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.orange.opacity(0.12))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "envelope.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.orange)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Outlook Calendar")
                                            .font(MMTypography.bodyMedium)
                                            .foregroundColor(MMColors.textPrimary)
                                        Text("Add Microsoft account in iPhone Settings to sync")
                                            .font(MMTypography.caption1)
                                            .foregroundColor(MMColors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(MMColors.textTertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }

                            sectionDivider

                            // Calendar permission status
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(MMColors.success.opacity(0.12))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "calendar.badge.checkmark")
                                        .font(.system(size: 16))
                                        .foregroundColor(MMColors.success)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Calendar Access")
                                        .font(MMTypography.bodyMedium)
                                        .foregroundColor(MMColors.textPrimary)
                                    Text("MeetMind reads your calendar to show upcoming meetings")
                                        .font(MMTypography.caption1)
                                        .foregroundColor(MMColors.textSecondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }

                    // MARK: - Integrations
                    settingsSection(header: "INTEGRATIONS") {
                        VStack(spacing: 0) {
                            // Teams Integration
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(red: 0.45, green: 0.34, blue: 0.86).opacity(0.12))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "bubble.left.and.text.bubble.right")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(red: 0.45, green: 0.34, blue: 0.86))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Microsoft Teams")
                                        .font(MMTypography.bodyMedium)
                                        .foregroundColor(MMColors.textPrimary)
                                    if teamsWebhookURL.isEmpty {
                                        Text("Add webhook URL to send notes to Teams")
                                            .font(MMTypography.caption1)
                                            .foregroundColor(MMColors.textSecondary)
                                    } else {
                                        Text("Connected")
                                            .font(MMTypography.caption1)
                                            .foregroundColor(MMColors.success)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            sectionDivider

                            TextField("Teams Webhook URL", text: $teamsWebhookURL)
                                .font(MMTypography.footnote)
                                .foregroundColor(MMColors.textPrimary)
                                .textContentType(.URL)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                            Text("Paste your Microsoft Teams Incoming Webhook URL to send meeting notes directly to a channel.")
                                .font(MMTypography.caption1)
                                .foregroundColor(MMColors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                        }
                    }

                    // MARK: - Appearance
                    settingsSection(header: "APPEARANCE") {
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "paintbrush")
                                    .foregroundColor(MMColors.primary)
                                    .frame(width: 20)
                                Text("Theme")
                                    .font(MMTypography.body)
                                    .foregroundColor(MMColors.textPrimary)
                                Spacer()
                                Picker("", selection: $appTheme) {
                                    Text("System").tag("system")
                                    Text("Dark").tag("dark")
                                    Text("Light").tag("light")
                                }
                                .pickerStyle(.menu)
                                .tint(MMColors.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                    }

                    // MARK: - Recording
                    settingsSection(header: "RECORDING") {
                        HStack {
                            Text("Quality")
                                .font(MMTypography.body)
                                .foregroundColor(MMColors.textPrimary)
                            Spacer()
                            Picker("Quality", selection: $recordingQuality) {
                                ForEach(RecordingQuality.allCases) { quality in
                                    Text(quality.rawValue).tag(quality.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(MMColors.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }

                    // MARK: - AI Summaries
                    settingsSection(header: "AI SUMMARIES") {
                        VStack(spacing: 0) {
                            HStack {
                                Text("Prompt Style")
                                    .font(MMTypography.body)
                                    .foregroundColor(MMColors.textPrimary)
                                Spacer()
                                Picker("Prompt Style", selection: $aiPromptStyle) {
                                    ForEach(AIPromptStyle.allCases) { style in
                                        Text(style.rawValue).tag(style.rawValue)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(MMColors.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            sectionDivider

                            NavigationLink {
                                PromptEditorView()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "text.badge.star")
                                        .foregroundColor(MMColors.primary)
                                        .frame(width: 20)
                                    Text("Customize AI Prompt")
                                        .font(MMTypography.body)
                                        .foregroundColor(MMColors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(MMColors.textTertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                        }
                    }

                    // MARK: - Storage
                    settingsSection(header: "STORAGE") {
                        VStack(spacing: 0) {
                            HStack {
                                Text("Audio Disk Usage")
                                    .font(MMTypography.body)
                                    .foregroundColor(MMColors.textPrimary)
                                Spacer()
                                Text(storageService.formatSize(storageService.totalAudioSize))
                                    .font(MMTypography.body)
                                    .foregroundColor(storageService.isStorageWarning ? MMColors.recording : MMColors.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            if storageService.isStorageWarning {
                                sectionDivider
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                        .font(.footnote)
                                    Text("Audio files are using more than 500 MB")
                                        .font(MMTypography.footnote)
                                        .foregroundColor(.orange)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }

                            sectionDivider

                            HStack {
                                Text("Audio Files")
                                    .font(MMTypography.body)
                                    .foregroundColor(MMColors.textPrimary)
                                Spacer()
                                Text("\(storageService.processedFileCount)")
                                    .font(MMTypography.body)
                                    .foregroundColor(MMColors.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            sectionDivider

                            HStack {
                                Text("Auto-delete audio")
                                    .font(MMTypography.body)
                                    .foregroundColor(MMColors.textPrimary)
                                Spacer()
                                Picker("Auto-delete audio", selection: $audioRetention) {
                                    ForEach(AudioRetention.allCases) { option in
                                        Text(option.rawValue).tag(option.rawValue)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(MMColors.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            sectionDivider

                            Toggle(isOn: $autoDeleteAudio) {
                                Text("Auto-delete audio after processing")
                                    .font(MMTypography.body)
                                    .foregroundColor(MMColors.textPrimary)
                            }
                            .tint(MMColors.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            Text("Audio is deleted after notes are generated. Only the transcript and notes are kept.")
                                .font(MMTypography.caption1)
                                .foregroundColor(MMColors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)

                            sectionDivider

                            Toggle(isOn: Binding(
                                get: { UserDefaults.standard.bool(forKey: "keepAudioFiles") },
                                set: { UserDefaults.standard.set($0, forKey: "keepAudioFiles") }
                            )) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Keep Audio Files")
                                        .font(MMTypography.body)
                                        .foregroundColor(MMColors.textPrimary)
                                    Text("When off, audio is deleted after transcription to save storage")
                                        .font(MMTypography.caption1)
                                        .foregroundColor(MMColors.textSecondary)
                                }
                            }
                            .tint(MMColors.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            let savedMB = UserDefaults.standard.double(forKey: "storageSavedMB")
                            if savedMB > 0 {
                                HStack {
                                    Image(systemName: "leaf.fill")
                                        .foregroundColor(MMColors.success)
                                    Text("Saved \(String(format: "%.0f", savedMB)) MB by not storing audio")
                                        .font(MMTypography.footnote)
                                        .foregroundColor(MMColors.textSecondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }

                            sectionDivider

                            Button {
                                showCleanupConfirmation = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "trash.circle")
                                        .foregroundColor(MMColors.recording)
                                        .frame(width: 20)
                                    Text("Clean Up Now")
                                        .font(MMTypography.body)
                                        .foregroundColor(MMColors.recording)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }

                            Text("Meeting briefs are kept forever. Only audio files are deleted.")
                                .font(MMTypography.caption1)
                                .foregroundColor(MMColors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                        }
                    }

                    // MARK: - Clients
                    settingsSection(header: "CLIENTS") {
                        NavigationLink {
                            ClientDictionaryView()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.2")
                                    .foregroundColor(MMColors.primary)
                                    .frame(width: 20)
                                Text("Client Dictionary")
                                    .font(MMTypography.body)
                                    .foregroundColor(MMColors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(MMColors.textTertiary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                    }

                    // MARK: - iCloud
                    settingsSection(header: "ICLOUD") {
                        VStack(spacing: 0) {
                            Toggle(isOn: Binding(
                                get: { iCloudSyncEnabled },
                                set: { newValue in
                                    if newValue {
                                        showICloudAlert = true
                                    } else {
                                        iCloudSyncEnabled = false
                                    }
                                }
                            )) {
                                Text("iCloud Sync")
                                    .font(MMTypography.body)
                                    .foregroundColor(MMColors.textPrimary)
                            }
                            .tint(MMColors.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            Text("Requires app restart to take effect. Your meetings and todos will sync across all your Apple devices.")
                                .font(MMTypography.caption1)
                                .foregroundColor(MMColors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                        }
                    }

                    // MARK: - Data
                    settingsSection(header: "DATA") {
                        VStack(spacing: 0) {
                            Button {
                                exportData()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(MMColors.primary)
                                        .frame(width: 20)
                                    Text("Export All Data")
                                        .font(MMTypography.body)
                                        .foregroundColor(MMColors.textPrimary)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }

                            sectionDivider
                        }
                    }

                    // Delete data — red tinted glass card
                    VStack(spacing: 0) {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "trash")
                                    .foregroundColor(MMColors.recording)
                                    .frame(width: 20)
                                Text("Delete All Data")
                                    .font(MMTypography.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(MMColors.recording)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(MMColors.recording.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(MMColors.recording.opacity(0.15), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)

                    // MARK: - Usage Stats
                    settingsSection(header: "USAGE STATS") {
                        VStack(spacing: 0) {
                            let eventCounts = analytics.getAllEventCounts().filter { $0.count > 0 }
                            if eventCounts.isEmpty {
                                Text("No activity yet")
                                    .font(MMTypography.footnote)
                                    .foregroundColor(MMColors.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                            } else {
                                ForEach(Array(eventCounts.enumerated()), id: \.element.event) { index, item in
                                    HStack {
                                        Text(item.event.displayName)
                                            .font(MMTypography.body)
                                            .foregroundColor(MMColors.textPrimary)
                                        Spacer()
                                        Text("\(item.count)")
                                            .font(MMTypography.body)
                                            .foregroundColor(MMColors.textSecondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)

                                    if index < eventCounts.count - 1 {
                                        sectionDivider
                                    }
                                }
                            }
                        }
                    }

                    // MARK: - Your Stats
                    settingsSection(header: "YOUR STATS") {
                        NavigationLink {
                            StatsView()
                        } label: {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(MMColors.warning)
                                Text("Productivity Stats & Streaks")
                                    .font(MMTypography.body)
                                    .foregroundColor(MMColors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(MMColors.textTertiary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                    }

                    // MARK: - Features
                    settingsSection(header: "FEATURES") {
                        VStack(spacing: 0) {
                            featureRow(icon: "mic.fill", color: MMColors.primary, title: "Meeting Recording", description: "One-tap recording with echo cancellation and background support")
                            sectionDivider
                            featureRow(icon: "brain", color: MMColors.success, title: "AI Meeting Notes", description: "TL;DR, decisions, action items table, open questions — Golden Template format")
                            sectionDivider
                            featureRow(icon: "bubble.left.and.bubble.right.fill", color: MMColors.info, title: "Smart Chat", description: "Ask about your meetings — instant stats, action items, and AI-powered search")
                            sectionDivider
                            featureRow(icon: "checklist", color: MMColors.warning, title: "Voice Todos", description: "Speak your tasks — AI extracts date, priority, and assignee automatically")
                            sectionDivider
                            featureRow(icon: "figure.mind.and.body", color: Color(red: 232/255, green: 67/255, blue: 147/255), title: "Communication Coach", description: "Filler words, speaking pace, talk ratio, and improvement tips")
                            sectionDivider
                            featureRow(icon: "waveform", color: MMColors.primary, title: "Live Transcription", description: "See real-time words on screen while recording")
                            sectionDivider
                            featureRow(icon: "bolt.fill", color: MMColors.warning, title: "Key Moments", description: "Auto-detected decisions, action items, and questions with timestamps")
                            sectionDivider
                            featureRow(icon: "face.smiling", color: MMColors.success, title: "Sentiment Analysis", description: "Positive, neutral, or negative tone detection for each meeting")
                            sectionDivider
                            featureRow(icon: "calendar", color: MMColors.info, title: "Calendar Integration", description: "See today's meetings and start recording with one tap")
                            sectionDivider
                            featureRow(icon: "flame.fill", color: MMColors.recording, title: "Streaks & Stats", description: "Track your meeting consistency and productivity scores")
                            sectionDivider
                            featureRow(icon: "wifi.slash", color: MMColors.textSecondary, title: "Offline Support", description: "Queue meetings for processing when you're back online")
                            sectionDivider
                            featureRow(icon: "applewatch", color: MMColors.primary, title: "Apple Watch", description: "Record meetings and view tasks from your wrist")
                        }
                    }

                    // MARK: - About
                    settingsSection(header: "ABOUT") {
                        VStack(spacing: 0) {
                            // Created by
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(MMColors.primary.opacity(0.12))
                                        .frame(width: 40, height: 40)
                                    Text("GM")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(MMColors.primary)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Created by Gaurav Modi")
                                        .font(MMTypography.bodyMedium)
                                        .foregroundColor(MMColors.textPrimary)
                                    Text("Built with SwiftUI + Groq AI")
                                        .font(MMTypography.caption1)
                                        .foregroundColor(MMColors.textSecondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            sectionDivider

                            HStack {
                                Text("Version")
                                    .font(MMTypography.body)
                                    .foregroundColor(MMColors.textPrimary)
                                Spacer()
                                Text("\(appVersion) (\(buildNumber))")
                                    .font(MMTypography.body)
                                    .foregroundColor(MMColors.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            sectionDivider

                            Link(destination: URL(string: "https://meetmind.app/privacy")!) {
                                HStack(spacing: 12) {
                                    Image(systemName: "hand.raised")
                                        .foregroundColor(MMColors.primary)
                                        .frame(width: 20)
                                    Text("Privacy Policy")
                                        .font(MMTypography.body)
                                        .foregroundColor(MMColors.textPrimary)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(MMColors.textTertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }

                            sectionDivider

                            Link(destination: URL(string: "https://meetmind.app/terms")!) {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(MMColors.primary)
                                        .frame(width: 20)
                                    Text("Terms of Service")
                                        .font(MMTypography.body)
                                        .foregroundColor(MMColors.textPrimary)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(MMColors.textTertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                        }
                    }

                    // Version footer
                    Text("Made with \u{2764}\u{FE0F} by Gaurav Modi")
                        .font(MMTypography.caption2)
                        .foregroundColor(MMColors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                }
                .padding(.top, 8)
            }
            .background(MMColors.background)
            .navigationTitle("Settings")
            .sheet(isPresented: $isEditingAPIKey) {
                apiKeyEditor
            }
            .sheet(isPresented: $isEditingGeminiKey) {
                geminiKeyEditor
            }
            .alert("Delete All Data", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all meetings, todos, and audio files. This action cannot be undone.")
            }
            .alert("Clean Up Audio", isPresented: $showCleanupConfirmation) {
                Button("Delete All Audio", role: .destructive) {
                    storageService.deleteAllProcessedAudio()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all \(storageService.processedFileCount) audio file(s) (\(storageService.formatSize(storageService.totalAudioSize))). Meeting briefs will be preserved.")
            }
            .alert("Enable iCloud Sync", isPresented: $showICloudAlert) {
                Button("Enable") {
                    iCloudSyncEnabled = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your meetings and todos will sync across all your Apple devices. You will need to restart the app for this change to take effect.")
            }
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll need to sign in again to sync your data across devices.")
            }
            .sheet(isPresented: $showExportSheet) {
                if !exportURLs.isEmpty {
                    ShareSheet(items: exportURLs)
                }
            }
            .onAppear {
                storageService.calculateDiskUsage()
            }
        }
    }

    // MARK: - Settings Section Builder

    @ViewBuilder
    private func settingsSection<Content: View>(header: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header)
                .font(MMTypography.overline)
                .tracking(1.2)
                .foregroundColor(MMColors.textTertiary)
                .padding(.horizontal, 20)

            content()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(MMColors.cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(MMColors.glassStroke, lineWidth: 1)
                        )
                )
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Section Divider

    private var sectionDivider: some View {
        Rectangle()
            .fill(MMColors.divider)
            .frame(height: 1)
            .padding(.leading, 16)
    }

    // MARK: - Export

    private func exportData() {
        // Fetch meetings and todos from Core Data
        let context = PersistenceController.shared.container.viewContext
        var meetings: [Meeting] = []
        var todos: [TodoItem] = []

        let meetingRequest = NSFetchRequest<NSManagedObject>(entityName: "CDMeeting")
        if let results = try? context.fetch(meetingRequest) {
            meetings = results.compactMap { obj -> Meeting? in
                guard let id = obj.value(forKey: "id") as? UUID,
                      let title = obj.value(forKey: "title") as? String,
                      let date = obj.value(forKey: "date") as? Date,
                      let statusRaw = obj.value(forKey: "status") as? String,
                      let createdAt = obj.value(forKey: "createdAt") as? Date else { return nil }
                return Meeting(
                    id: id,
                    title: title,
                    date: date,
                    duration: obj.value(forKey: "duration") as? TimeInterval ?? 0,
                    audioFilePath: obj.value(forKey: "audioFilePath") as? String,
                    clientName: obj.value(forKey: "clientName") as? String,
                    status: MeetingStatus(rawValue: statusRaw) ?? .complete,
                    briefSummary: obj.value(forKey: "briefSummary") as? String,
                    rawTranscript: obj.value(forKey: "rawTranscript") as? String,
                    userNotes: obj.value(forKey: "userNotes") as? String,
                    createdAt: createdAt
                )
            }
        }

        let todoRequest = NSFetchRequest<NSManagedObject>(entityName: "CDTodoItem")
        if let results = try? context.fetch(todoRequest) {
            todos = results.compactMap { obj -> TodoItem? in
                guard let id = obj.value(forKey: "id") as? UUID,
                      let title = obj.value(forKey: "title") as? String,
                      let dueDate = obj.value(forKey: "dueDate") as? Date,
                      let createdAt = obj.value(forKey: "createdAt") as? Date else { return nil }
                return TodoItem(
                    id: id,
                    title: title,
                    dueDate: dueDate,
                    priority: TodoPriority(rawValue: obj.value(forKey: "priority") as? String ?? "medium") ?? .medium,
                    clientTag: obj.value(forKey: "clientTag") as? String,
                    source: TodoSource(rawValue: obj.value(forKey: "source") as? String ?? "manual") ?? .manual,
                    sourceMeetingId: obj.value(forKey: "sourceMeetingId") as? UUID,
                    isCompleted: obj.value(forKey: "isCompleted") as? Bool ?? false,
                    completedAt: obj.value(forKey: "completedAt") as? Date,
                    createdAt: createdAt
                )
            }
        }

        // Generate export files
        var urls: [URL] = []
        if let jsonURL = DataExportService.exportAllAsJSON(meetings: meetings, todos: todos) {
            urls.append(jsonURL)
        }
        urls.append(contentsOf: DataExportService.exportAllAsCSV(meetings: meetings, todos: todos))

        guard !urls.isEmpty else { return }

        exportURLs = urls
        showExportSheet = true
    }

    // MARK: - API Key Editor Sheet

    private var apiKeyEditor: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter your Groq API key")
                    .font(MMTypography.headline)
                    .foregroundColor(MMColors.textPrimary)

                MMTextField(
                    placeholder: "gsk_...",
                    text: $apiKeyDraft,
                    icon: "key",
                    isSecure: true
                )
                .padding(.horizontal)

                Button {
                    if let url = URL(string: "https://console.groq.com/keys") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Get a free API key from Groq")
                        .font(MMTypography.footnote)
                        .foregroundColor(MMColors.primary)
                }

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isEditingAPIKey = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        apiKey = apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        isEditingAPIKey = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Gemini Key Editor Sheet

    private var geminiKeyEditor: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter your Google Gemini API key")
                    .font(MMTypography.headline)
                    .foregroundColor(MMColors.textPrimary)

                MMTextField(
                    placeholder: "AIza...",
                    text: $geminiKeyDraft,
                    icon: "key",
                    isSecure: true
                )
                .padding(.horizontal)

                Button {
                    if let url = URL(string: "https://aistudio.google.com/apikey") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Get a free API key from Google AI Studio")
                        .font(MMTypography.footnote)
                        .foregroundColor(MMColors.primary)
                }

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Gemini Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isEditingGeminiKey = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        geminiAPIKey = geminiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        isEditingGeminiKey = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - App Info

    private func deleteAllData() {
        // Delete all meetings
        for meeting in MeetingService.shared.meetings {
            MeetingService.shared.deleteMeeting(meeting)
        }
        // Delete all todos
        for todo in TodoService.shared.todos {
            TodoService.shared.deleteTodo(todo)
        }
        // Delete all audio files
        StorageManagementService.shared.deleteAllProcessedAudio()
        // Clear cached data
        UserDefaults.standard.removeObject(forKey: "widgetData")
        UserDefaults.standard.removeObject(forKey: "peopleCache")
    }

    private func featureRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MMTypography.bodyMedium)
                    .foregroundColor(MMColors.textPrimary)
                Text(description)
                    .font(MMTypography.caption1)
                    .foregroundColor(MMColors.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
