import SwiftUI
import AVFoundation

struct ProfileSetupView: View {
    @EnvironmentObject var authService: AuthService
    @AppStorage("hasCompletedOnboarding") private var hasOnboarded = false
    @AppStorage("groqAPIKey") private var apiKey = ""

    @State private var currentStep = 0
    @State private var selectedRole: WorkRole?
    @State private var roleDescription = ""
    @State private var selectedTools: Set<MeetingTool> = []
    @State private var selectedFrequency: MeetingFrequency = .moderate
    @State private var micPermissionGranted = false
    @State private var apiKeyInput = ""
    @State private var isValidatingKey = false
    @State private var keyError: String?

    private let totalSteps = 4

    var body: some View {
        ZStack {
            MMColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                TabView(selection: $currentStep) {
                    micPermissionStep.tag(0)
                    roleStep.tag(1)
                    toolsStep.tag(2)
                    apiKeyStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(MMColors.glass)
                    .frame(height: 4)
                Capsule()
                    .fill(MMColors.primary)
                    .frame(width: geo.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps), height: 4)
                    .animation(.spring(response: 0.4), value: currentStep)
            }
        }
        .frame(height: 4)
    }

    private var micPermissionStep: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(MMColors.primary.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "mic.fill")
                    .font(.system(size: 44))
                    .foregroundColor(MMColors.primary)
            }

            VStack(spacing: 8) {
                Text("Microphone Access")
                    .font(MMTypography.title2)
                    .foregroundColor(MMColors.textPrimary)

                Text("MeetMind records meetings through your device microphone to create transcripts and AI-powered summaries.")
                    .font(MMTypography.body)
                    .foregroundColor(MMColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            Spacer()

            VStack(spacing: 12) {
                MMButton("Allow Microphone", icon: "mic.fill") {
                    requestMicPermission()
                }

                if micPermissionGranted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(MMColors.success)
                        Text("Permission granted")
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.success)
                    }
                }

                Button("Skip for now") {
                    currentStep = 1
                }
                .font(MMTypography.footnote)
                .foregroundColor(MMColors.textTertiary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private var roleStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("What do you do?")
                    .font(MMTypography.title2)
                    .foregroundColor(MMColors.textPrimary)

                Text("This helps MeetMind tailor summaries to your work style.")
                    .font(MMTypography.subheadline)
                    .foregroundColor(MMColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(WorkRole.allCases, id: \.self) { role in
                        Button {
                            selectedRole = role
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: role.icon)
                                    .font(.system(size: 24))
                                Text(role.displayName)
                                    .font(MMTypography.footnoteMedium)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .foregroundColor(selectedRole == role ? .white : MMColors.textPrimary)
                            .background(selectedRole == role ? MMColors.primary : MMColors.glass)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedRole == role ? MMColors.primary : MMColors.glassStroke, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)

                if selectedRole != nil {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tell us more (optional)")
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.textSecondary)
                        TextField("e.g., Data engineer focused on cloud migrations", text: $roleDescription)
                            .font(MMTypography.body)
                            .padding(12)
                            .background(MMColors.glass)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(MMColors.glassStroke, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }

            VStack(spacing: 12) {
                MMButton("Continue", icon: "arrow.right") {
                    currentStep = 2
                }

                Button("Skip") {
                    currentStep = 2
                }
                .font(MMTypography.footnote)
                .foregroundColor(MMColors.textTertiary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private var toolsStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Your meeting tools")
                    .font(MMTypography.title2)
                    .foregroundColor(MMColors.textPrimary)

                Text("Select the tools you use for meetings.")
                    .font(MMTypography.subheadline)
                    .foregroundColor(MMColors.textSecondary)
            }
            .padding(.top, 40)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(MeetingTool.allCases, id: \.self) { tool in
                        Button {
                            if selectedTools.contains(tool) {
                                selectedTools.remove(tool)
                            } else {
                                selectedTools.insert(tool)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: tool.icon)
                                    .font(.system(size: 20))
                                    .frame(width: 28)
                                Text(tool.displayName)
                                    .font(MMTypography.bodyMedium)
                                Spacer()
                                if selectedTools.contains(tool) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(MMColors.primary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .foregroundColor(MMColors.textPrimary)
                            .background(selectedTools.contains(tool) ? MMColors.primary.opacity(0.1) : MMColors.glass)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedTools.contains(tool) ? MMColors.primary.opacity(0.3) : MMColors.glassStroke, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 10) {
                    Text("How often do you have meetings?")
                        .font(MMTypography.footnoteMedium)
                        .foregroundColor(MMColors.textSecondary)
                        .padding(.top, 16)

                    ForEach(MeetingFrequency.allCases, id: \.self) { freq in
                        Button {
                            selectedFrequency = freq
                        } label: {
                            HStack {
                                Text(freq.displayName.capitalized)
                                    .font(MMTypography.body)
                                Spacer()
                                if selectedFrequency == freq {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(MMColors.primary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .foregroundColor(MMColors.textPrimary)
                            .background(selectedFrequency == freq ? MMColors.primary.opacity(0.1) : MMColors.glass)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            MMButton("Continue", icon: "arrow.right") {
                currentStep = 3
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private var apiKeyStep: some View {
        VStack(spacing: 24) {
            Spacer()

            if !apiKey.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(MMColors.success.opacity(0.12))
                            .frame(width: 100, height: 100)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(MMColors.success)
                    }

                    Text("You're all set!")
                        .font(MMTypography.title2)
                        .foregroundColor(MMColors.textPrimary)

                    Text("Your Groq API key is configured and ready.")
                        .font(MMTypography.body)
                        .foregroundColor(MMColors.textSecondary)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 44))
                        .foregroundColor(MMColors.primary)

                    Text("Connect to Groq")
                        .font(MMTypography.title2)
                        .foregroundColor(MMColors.textPrimary)

                    Text("Enter your Groq API key for AI-powered transcription and summaries.")
                        .font(MMTypography.subheadline)
                        .foregroundColor(MMColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)

                    VStack(spacing: 8) {
                        MMTextField(
                            placeholder: "gsk_...",
                            text: $apiKeyInput,
                            icon: "key",
                            isSecure: true
                        )

                        if isValidatingKey {
                            HStack(spacing: 6) {
                                ProgressView().controlSize(.mini)
                                Text("Verifying...")
                                    .font(MMTypography.caption1)
                            }
                            .foregroundColor(MMColors.textSecondary)
                        } else if let error = keyError {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                Text(error)
                                    .font(MMTypography.caption1)
                            }
                            .foregroundColor(MMColors.recording)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                MMButton(apiKey.isEmpty ? "Verify & Continue" : "Get Started", icon: apiKey.isEmpty ? "checkmark" : "arrow.right", isLoading: isValidatingKey) {
                    if apiKey.isEmpty {
                        validateAndSaveKey()
                    } else {
                        completeOnboarding()
                    }
                }

                if apiKey.isEmpty {
                    MMButton("Get a free API key", icon: "safari", style: .ghost) {
                        if let url = URL(string: "https://console.groq.com/keys") {
                            UIApplication.shared.open(url)
                        }
                    }

                    Button("Skip for now") {
                        completeOnboarding()
                    }
                    .font(MMTypography.footnote)
                    .foregroundColor(MMColors.textTertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private func requestMicPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            Task { @MainActor in
                micPermissionGranted = granted
                if granted {
                    try? await Task.sleep(for: .seconds(0.8))
                    currentStep = 1
                }
            }
        }
    }

    private func validateAndSaveKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            keyError = "Please enter an API key."
            return
        }
        guard trimmed.hasPrefix("gsk_") else {
            keyError = "Groq API keys start with \"gsk_\"."
            return
        }
        guard trimmed.count > 20 else {
            keyError = "That key looks too short."
            return
        }

        keyError = nil
        isValidatingKey = true

        Task {
            let url = URL(string: "https://api.groq.com/openai/v1/models")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(trimmed)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 10

            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                let valid = (response as? HTTPURLResponse)?.statusCode == 200

                await MainActor.run {
                    isValidatingKey = false
                    if valid {
                        apiKey = trimmed
                        KeychainService.save(key: trimmed)
                        completeOnboarding()
                    } else {
                        keyError = "Invalid key — could not connect to Groq."
                    }
                }
            } catch {
                await MainActor.run {
                    isValidatingKey = false
                    keyError = "Connection failed. Check your internet."
                }
            }
        }
    }

    private func completeOnboarding() {
        var profile = authService.userProfile
        profile.role = selectedRole ?? .other
        profile.roleDescription = roleDescription
        profile.meetingTools = Array(selectedTools)
        profile.meetingFrequency = selectedFrequency
        profile.onboardingComplete = true
        authService.updateProfile(profile)

        hasOnboarded = true
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(AuthService.shared)
}
