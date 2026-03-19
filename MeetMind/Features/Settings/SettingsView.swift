import SwiftUI
import CoreData

struct SettingsView: View {
    @AppStorage("groqAPIKey") private var apiKey = ""
    @AppStorage("recordingQuality") private var recordingQuality = RecordingQuality.standard.rawValue
    @AppStorage("aiPromptStyle") private var aiPromptStyle = AIPromptStyle.concise.rawValue
    @AppStorage("audioRetention") private var audioRetention = AudioRetention.fourteenDays.rawValue
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false

    @StateObject private var storageService = StorageManagementService.shared
    @StateObject private var analytics = AnalyticsService.shared

    @State private var isEditingAPIKey = false
    @State private var apiKeyDraft = ""
    @State private var showExportSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showCleanupConfirmation = false
    @State private var exportURLs: [URL] = []

    private var maskedKey: String {
        guard apiKey.count > 8 else { return String(repeating: "\u{2022}", count: max(apiKey.count, 8)) }
        let prefix = String(apiKey.prefix(4))
        let suffix = String(apiKey.suffix(4))
        return "\(prefix)\(String(repeating: "\u{2022}", count: 8))\(suffix)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
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

                            Text("Your key is stored locally on this device.")
                                .font(MMTypography.caption1)
                                .foregroundColor(MMColors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
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
                            Toggle(isOn: $iCloudSyncEnabled) {
                                Text("iCloud Sync")
                                    .font(MMTypography.body)
                                    .foregroundColor(MMColors.textPrimary)
                            }
                            .tint(MMColors.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            Text("Sync meetings and todos across your devices.")
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

                    // MARK: - About
                    settingsSection(header: "ABOUT") {
                        VStack(spacing: 0) {
                            HStack {
                                Text("Version")
                                    .font(MMTypography.body)
                                    .foregroundColor(MMColors.textPrimary)
                                Spacer()
                                Text(appVersion)
                                    .font(MMTypography.body)
                                    .foregroundColor(MMColors.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            sectionDivider

                            HStack {
                                Text("Build")
                                    .font(MMTypography.body)
                                    .foregroundColor(MMColors.textPrimary)
                                Spacer()
                                Text(buildNumber)
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
                    Text("MeetMind v\(appVersion) (\(buildNumber))")
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
            .alert("Delete All Data", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    // TODO: Implement data deletion
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

    // MARK: - App Info

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
