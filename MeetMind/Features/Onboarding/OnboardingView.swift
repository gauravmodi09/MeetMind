import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasOnboarded = false
    @AppStorage("groqAPIKey") private var apiKey = ""

    @State private var apiKeyInput = ""
    @State private var isValidating = false
    @State private var validationError: String?

    var body: some View {
        ZStack {
            MMColors.background.ignoresSafeArea()

            // Go straight to API key entry (or skip if already set)
            if !apiKey.isEmpty {
                // Key already loaded from Secrets.plist — go straight in
                VStack(spacing: 24) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(MMColors.primary.opacity(0.12))
                            .frame(width: 120, height: 120)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(MMColors.success)
                    }

                    Text("Welcome to MeetMind")
                        .font(MMTypography.title1)
                        .foregroundColor(MMColors.textPrimary)

                    Text("Your AI meeting assistant is ready.")
                        .font(MMTypography.body)
                        .foregroundColor(MMColors.textSecondary)

                    Spacer()

                    MMButton("Let's Go", icon: "arrow.right") {
                        hasOnboarded = true
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
            } else {
                apiKeyEntryView
            }
        }
    }

    // MARK: - API Key Entry

    private var apiKeyEntryView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "key.fill")
                    .font(.system(size: 48))
                    .foregroundColor(MMColors.primary)

                VStack(spacing: 8) {
                    Text("Connect to Groq")
                        .font(MMTypography.title2)
                        .foregroundColor(MMColors.textPrimary)

                    Text("Enter your Groq API key to enable AI-powered meeting summaries and transcription.")
                        .font(MMTypography.subheadline)
                        .foregroundColor(MMColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                }

                VStack(spacing: 12) {
                    MMTextField(
                        placeholder: "gsk_...",
                        text: $apiKeyInput,
                        icon: "key",
                        isSecure: true
                    )

                    if isValidating {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.mini)
                            Text("Verifying...")
                                .font(MMTypography.caption1)
                        }
                        .foregroundColor(MMColors.textSecondary)
                    } else if let error = validationError {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                            Text(error)
                                .font(MMTypography.caption1)
                        }
                        .foregroundColor(MMColors.recording)
                    }

                    Text("Your key is stored locally on-device and never sent to our servers.")
                        .font(MMTypography.caption1)
                        .foregroundColor(MMColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 12) {
                MMButton("Continue", icon: "checkmark", isLoading: isValidating) {
                    validateAndSave()
                }

                MMButton("Get a free API key", icon: "safari", style: .ghost) {
                    if let url = URL(string: "https://console.groq.com/keys") {
                        UIApplication.shared.open(url)
                    }
                }

                Button("Skip for now") {
                    hasOnboarded = true
                }
                .font(MMTypography.footnote)
                .foregroundColor(MMColors.textTertiary)
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Validation

    private func validateAndSave() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationError = "Please enter an API key."
            return
        }
        guard trimmed.hasPrefix("gsk_") else {
            validationError = "Groq API keys start with \"gsk_\". Please check your key."
            return
        }
        guard trimmed.count > 20 else {
            validationError = "That key looks too short. Please check and try again."
            return
        }

        validationError = nil
        isValidating = true

        Task {
            let isValid = await testAPIKey(trimmed)
            await MainActor.run {
                isValidating = false
                if isValid {
                    apiKey = trimmed
                    KeychainService.save(key: trimmed)
                    hasOnboarded = true
                } else {
                    validationError = "Invalid key — could not connect to Groq. Please check and try again."
                }
            }
        }
    }

    private func testAPIKey(_ key: String) async -> Bool {
        let url = URL(string: "https://api.groq.com/openai/v1/models")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                return http.statusCode == 200
            }
            return false
        } catch {
            return false
        }
    }
}

#Preview {
    OnboardingView()
}
