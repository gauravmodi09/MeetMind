import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasOnboarded = false
    @AppStorage("groqAPIKey") private var apiKey = ""

    @State private var currentPage = 0
    @State private var showAPIKeyEntry = false
    @State private var apiKeyInput = ""
    @State private var isValidating = false
    @State private var validationError: String?
    @State private var showDemoMeeting = false

    var body: some View {
        ZStack {
            MMColors.background.ignoresSafeArea()

            if showDemoMeeting {
                DemoMeetingView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if showAPIKeyEntry {
                apiKeyEntryView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                onboardingPager
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showAPIKeyEntry)
        .animation(.easeInOut(duration: 0.35), value: showDemoMeeting)
    }

    // MARK: - Onboarding Pages

    private var onboardingPager: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                OnboardingPage(
                    icon: "mic.fill",
                    iconColor: MMColors.primary,
                    title: "Record meetings effortlessly",
                    description: "One tap to start recording. MeetMind captures everything so you can stay focused on the conversation."
                )
                .tag(0)

                OnboardingPage(
                    icon: "brain",
                    iconColor: MMColors.success,
                    title: "AI structures your notes",
                    description: "Get instant summaries, key decisions, and action items -- powered by Groq's lightning-fast AI."
                )
                .tag(1)

                OnboardingPage(
                    icon: "checklist",
                    iconColor: MMColors.info,
                    title: "Voice todos with smart dates",
                    description: "Say \"remind me to send the proposal by Friday\" and MeetMind handles the rest with natural language understanding."
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Page indicators + button
            VStack(spacing: 28) {
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? MMColors.primary : MMColors.border)
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.25), value: currentPage)
                    }
                }

                MMButton(
                    currentPage == 2 ? "Get Started" : "Next",
                    icon: currentPage == 2 ? "arrow.right" : nil
                ) {
                    if currentPage < 2 {
                        withAnimation { currentPage += 1 }
                    } else {
                        // If API key already loaded from Secrets.plist, skip key entry
                        if !apiKey.isEmpty {
                            showDemoMeeting = true
                        } else {
                            showAPIKeyEntry = true
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 48)
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

                    if let error = validationError {
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
                    showDemoMeeting = true
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

        // Simulate a brief validation delay; real validation would hit the Groq API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            apiKey = trimmed
            isValidating = false
            showDemoMeeting = true
        }
    }
}

// MARK: - Onboarding Page

private struct OnboardingPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(iconColor)
            }

            VStack(spacing: 12) {
                Text(title)
                    .font(MMTypography.title1)
                    .foregroundColor(MMColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(MMTypography.body)
                    .foregroundColor(MMColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
