# Phase 1: Onboarding + Authentication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Google Sign-In authentication with Firebase, user profiling onboarding, and session management to MeetMind iOS app.

**Architecture:** Firebase Auth with Google Sign-In provider handles authentication. A new `AuthService` singleton manages sign-in state, session persistence, and user profile. The existing `OnboardingView` is replaced with a multi-step flow: sign-in → mic permission → user profiling. The app entry point (`MeetMindApp.swift`) gates on auth state.

**Tech Stack:** Firebase Auth, Google Sign-In SDK (via SPM), SwiftUI, Keychain (existing `KeychainService`)

---

## File Structure

| Action | Path | Responsibility |
|--------|------|---------------|
| Create | `MeetMind/Services/AuthService.swift` | Firebase Auth wrapper, sign-in/out, session state, user profile |
| Create | `MeetMind/Data/UserProfile.swift` | UserProfile model with role, tools, frequency |
| Create | `MeetMind/Features/Auth/Views/SignInView.swift` | Google Sign-In button + branded splash screen |
| Create | `MeetMind/Features/Auth/Views/ProfileSetupView.swift` | 3-step onboarding: mic permission, role, tools |
| Modify | `MeetMind/App/MeetMindApp.swift` | Gate on auth state, inject AuthService |
| Modify | `MeetMind/Features/Onboarding/OnboardingView.swift` | Replace with new auth-aware flow |
| Modify | `MeetMind/Features/Settings/SettingsView.swift` | Add profile section, sign-out button |
| Modify | `project.yml` | Add Firebase + GoogleSignIn SPM dependencies |
| Modify | `MeetMind/Resources/Info.plist` | Add Google OAuth URL scheme |

---

### Task 1: Add Firebase + Google Sign-In Dependencies

**Files:**
- Modify: `project.yml`
- Modify: `MeetMind/Resources/Info.plist`

- [ ] **Step 1: Add SPM dependencies to project.yml**

Add Firebase and GoogleSignIn packages to the Tuist project configuration:

```yaml
# Add after the existing settings block, before targets:
packages:
  FirebaseAuth:
    url: "https://github.com/firebase/firebase-ios-sdk"
    from: "11.0.0"
  GoogleSignIn:
    url: "https://github.com/google/GoogleSignIn-iOS"
    from: "8.0.0"
```

Then add dependencies to the MeetMind target:

```yaml
# Add inside targets > MeetMind, after sources:
    dependencies:
      - package: FirebaseAuth
        product: FirebaseAuth
      - package: GoogleSignIn
        product: GoogleSignIn
        product: GoogleSignInSwift
```

- [ ] **Step 2: Create Firebase project and download GoogleService-Info.plist**

1. Go to https://console.firebase.google.com
2. Create project "MeetMind"
3. Add iOS app with bundle ID `com.meetmind.app`
4. Download `GoogleService-Info.plist`
5. Place at `MeetMind/Resources/GoogleService-Info.plist`
6. From the plist, copy the `REVERSED_CLIENT_ID` value (e.g., `com.googleusercontent.apps.XXXX`)

- [ ] **Step 3: Add Google OAuth URL scheme to Info.plist**

Open `MeetMind/Resources/Info.plist` and add the URL scheme. Add this inside the top-level `<dict>`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>REVERSED_CLIENT_ID_FROM_STEP_2</string>
        </array>
    </dict>
</array>
```

- [ ] **Step 4: Enable Google Sign-In in Firebase Console**

1. In Firebase Console → Authentication → Sign-in method
2. Enable "Google" provider
3. Set support email

- [ ] **Step 5: Generate project and verify build**

Run: `cd /Users/modi/R&D/MeetMind && tuist generate`
Then build in Xcode to verify dependencies resolve.

- [ ] **Step 6: Commit**

```bash
git add project.yml MeetMind/Resources/GoogleService-Info.plist MeetMind/Resources/Info.plist
git commit -m "infra: add Firebase Auth + Google Sign-In SPM dependencies"
```

---

### Task 2: Create UserProfile Model

**Files:**
- Create: `MeetMind/Data/UserProfile.swift`

- [ ] **Step 1: Create the UserProfile model**

Create `MeetMind/Data/UserProfile.swift`:

```swift
import Foundation

// MARK: - UserProfile

struct UserProfile: Codable {
    var role: WorkRole
    var roleDescription: String
    var meetingTools: [MeetingTool]
    var meetingFrequency: MeetingFrequency
    var onboardingComplete: Bool

    init(
        role: WorkRole = .other,
        roleDescription: String = "",
        meetingTools: [MeetingTool] = [],
        meetingFrequency: MeetingFrequency = .moderate,
        onboardingComplete: Bool = false
    ) {
        self.role = role
        self.roleDescription = roleDescription
        self.meetingTools = meetingTools
        self.meetingFrequency = meetingFrequency
        self.onboardingComplete = onboardingComplete
    }

    /// Context string injected into AI prompts for personalized summaries
    var aiContextString: String {
        var parts: [String] = []
        parts.append("The user is a \(role.displayName)")
        if !roleDescription.isEmpty {
            parts.append("who describes their work as: \(roleDescription)")
        }
        if !meetingTools.isEmpty {
            let toolNames = meetingTools.map(\.displayName).joined(separator: ", ")
            parts.append("They primarily use \(toolNames) for meetings")
        }
        parts.append("and have meetings \(meetingFrequency.displayName)")
        return parts.joined(separator: ". ") + "."
    }
}

// MARK: - WorkRole

enum WorkRole: String, Codable, CaseIterable {
    case consulting
    case engineering
    case sales
    case product
    case executive
    case design
    case dataScience
    case other

    var displayName: String {
        switch self {
        case .consulting:  return "Consultant"
        case .engineering:  return "Engineer"
        case .sales:        return "Sales Professional"
        case .product:      return "Product Manager"
        case .executive:    return "Executive / Leadership"
        case .design:       return "Designer"
        case .dataScience:  return "Data Scientist"
        case .other:        return "Other"
        }
    }

    var icon: String {
        switch self {
        case .consulting:  return "briefcase.fill"
        case .engineering:  return "wrench.and.screwdriver.fill"
        case .sales:        return "chart.line.uptrend.xyaxis"
        case .product:      return "square.grid.2x2.fill"
        case .executive:    return "crown.fill"
        case .design:       return "paintbrush.fill"
        case .dataScience:  return "chart.bar.fill"
        case .other:        return "person.fill"
        }
    }
}

// MARK: - MeetingTool

enum MeetingTool: String, Codable, CaseIterable {
    case teams
    case googleMeet
    case zoom
    case slack
    case webex

    var displayName: String {
        switch self {
        case .teams:      return "Microsoft Teams"
        case .googleMeet: return "Google Meet"
        case .zoom:       return "Zoom"
        case .slack:      return "Slack"
        case .webex:      return "Webex"
        }
    }

    var icon: String {
        switch self {
        case .teams:      return "person.3.fill"
        case .googleMeet: return "video.fill"
        case .zoom:       return "video.circle.fill"
        case .slack:      return "number"
        case .webex:      return "phone.circle.fill"
        }
    }
}

// MARK: - MeetingFrequency

enum MeetingFrequency: String, Codable, CaseIterable {
    case daily
    case frequent    // 3-5 per week
    case moderate    // 1-2 per week
    case occasional  // a few per month

    var displayName: String {
        switch self {
        case .daily:      return "daily"
        case .frequent:   return "3-5 times per week"
        case .moderate:   return "1-2 times per week"
        case .occasional: return "a few times per month"
        }
    }
}

// MARK: - UserProfile Persistence

extension UserProfile {
    private static let storageKey = "meetmind_user_profile"

    static func load() -> UserProfile {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return UserProfile()
        }
        return profile
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: UserProfile.storageKey)
        }
    }
}
```

- [ ] **Step 2: Verify it compiles**

Build the project in Xcode. No tests needed for a pure data model.

- [ ] **Step 3: Commit**

```bash
git add MeetMind/Data/UserProfile.swift
git commit -m "feat: add UserProfile model with role, tools, frequency"
```

---

### Task 3: Create AuthService

**Files:**
- Create: `MeetMind/Services/AuthService.swift`

- [ ] **Step 1: Create AuthService**

Create `MeetMind/Services/AuthService.swift`:

```swift
import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isSignedIn = false
    @Published var isLoading = true
    @Published var userProfile = UserProfile.load()
    @Published var signInError: String?

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    private init() {
        // Configure Firebase on first access
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Listen for auth state changes
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isSignedIn = user != nil
                self?.isLoading = false
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async {
        signInError = nil

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            signInError = "Unable to find root view controller."
            return
        }

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            signInError = "Firebase not configured. Missing GoogleService-Info.plist."
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                signInError = "Missing ID token from Google."
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            self.currentUser = authResult.user
            self.isSignedIn = true
        } catch {
            signInError = error.localizedDescription
        }
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            currentUser = nil
            isSignedIn = false
        } catch {
            signInError = error.localizedDescription
        }
    }

    // MARK: - Continue Without Account

    func continueWithoutAccount() {
        // Sign in anonymously so the app works without Google
        Task {
            do {
                let result = try await Auth.auth().signInAnonymously()
                self.currentUser = result.user
                self.isSignedIn = true
            } catch {
                // If anonymous auth fails, just set signed in locally
                self.isSignedIn = true
                self.isLoading = false
            }
        }
    }

    // MARK: - Profile Management

    func updateProfile(_ profile: UserProfile) {
        self.userProfile = profile
        profile.save()
    }

    var displayName: String {
        currentUser?.displayName ?? "User"
    }

    var email: String {
        currentUser?.email ?? ""
    }

    var photoURL: URL? {
        currentUser?.photoURL
    }

    var isAnonymous: Bool {
        currentUser?.isAnonymous ?? true
    }

    // MARK: - Delete Account

    func deleteAccount() async throws {
        try await currentUser?.delete()
        UserProfile().save() // Reset profile
        UserDefaults.standard.removeObject(forKey: "meetmind_user_profile")
        currentUser = nil
        isSignedIn = false
    }
}
```

- [ ] **Step 2: Verify it compiles**

Build in Xcode. Ensure Firebase and GoogleSignIn imports resolve correctly.

- [ ] **Step 3: Commit**

```bash
git add MeetMind/Services/AuthService.swift
git commit -m "feat: add AuthService with Google Sign-In + Firebase Auth"
```

---

### Task 4: Create SignInView

**Files:**
- Create: `MeetMind/Features/Auth/Views/SignInView.swift`

- [ ] **Step 1: Create the sign-in screen**

Create `MeetMind/Features/Auth/Views/SignInView.swift`:

```swift
import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    MMColors.primary.opacity(0.15),
                    MMColors.background,
                    MMColors.primary.opacity(0.08)
                ],
                startPoint: isAnimating ? .topLeading : .bottomTrailing,
                endPoint: isAnimating ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: isAnimating)

            VStack(spacing: 0) {
                Spacer()

                // Logo + branding
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(MMColors.primary.opacity(0.12))
                            .frame(width: 120, height: 120)
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(MMColors.primary)
                    }

                    Text("MeetMind")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(MMColors.textPrimary)

                    Text("AI-powered meeting intelligence")
                        .font(MMTypography.body)
                        .foregroundColor(MMColors.textSecondary)
                }

                Spacer()

                // Sign-in buttons
                VStack(spacing: 12) {
                    // Google Sign-In button
                    Button {
                        Task {
                            await authService.signInWithGoogle()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20))
                            Text("Continue with Google")
                                .font(MMTypography.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(MMColors.textPrimary)
                        .background(MMColors.glass)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(MMColors.glassStroke, lineWidth: 1)
                        )
                    }

                    // Continue without account
                    Button {
                        authService.continueWithoutAccount()
                    } label: {
                        Text("Continue without account")
                            .font(MMTypography.footnote)
                            .foregroundColor(MMColors.textTertiary)
                    }
                    .padding(.top, 4)

                    if let error = authService.signInError {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                            Text(error)
                                .font(MMTypography.caption1)
                        }
                        .foregroundColor(MMColors.recording)
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthService.shared)
}
```

- [ ] **Step 2: Verify it compiles**

Build in Xcode.

- [ ] **Step 3: Commit**

```bash
git add MeetMind/Features/Auth/Views/SignInView.swift
git commit -m "feat: add SignInView with Google Sign-In + branded splash"
```

---

### Task 5: Create ProfileSetupView (3-Step Onboarding)

**Files:**
- Create: `MeetMind/Features/Auth/Views/ProfileSetupView.swift`

- [ ] **Step 1: Create the profile setup flow**

Create `MeetMind/Features/Auth/Views/ProfileSetupView.swift`:

```swift
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

    private let totalSteps = 4 // mic, role, tools, API key

    var body: some View {
        ZStack {
            MMColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                progressBar
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                // Step content
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

    // MARK: - Progress Bar

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

    // MARK: - Step 1: Microphone Permission

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

    // MARK: - Step 2: Role Selection

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

                // Free-text description
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

    // MARK: - Step 3: Meeting Tools + Frequency

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
                // Tool selection
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

                // Frequency picker
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

    // MARK: - Step 4: API Key (reuses existing logic)

    private var apiKeyStep: some View {
        VStack(spacing: 24) {
            Spacer()

            if !apiKey.isEmpty {
                // Key already loaded — ready to go
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
                // API key entry
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

    // MARK: - Actions

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
        // Save profile
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
```

- [ ] **Step 2: Verify it compiles**

Build in Xcode.

- [ ] **Step 3: Commit**

```bash
git add MeetMind/Features/Auth/Views/ProfileSetupView.swift
git commit -m "feat: add ProfileSetupView with mic permission, role, tools, API key steps"
```

---

### Task 6: Update MeetMindApp.swift — Wire Auth Flow

**Files:**
- Modify: `MeetMind/App/MeetMindApp.swift`

- [ ] **Step 1: Replace the app entry point with auth-aware routing**

Replace the entire contents of `MeetMind/App/MeetMindApp.swift`:

```swift
import SwiftUI
import FirebaseCore

@main
struct MeetMindApp: App {
    let persistence: PersistenceController = {
        if UserDefaults.standard.bool(forKey: "iCloudSyncEnabled") {
            return PersistenceController.cloudKitController() ?? PersistenceController.shared
        }
        return PersistenceController.shared
    }()

    @StateObject private var authService = AuthService.shared
    @AppStorage("hasCompletedOnboarding") var hasOnboarded = false
    @AppStorage("groqAPIKey") var apiKey = ""
    @AppStorage("appTheme") var appTheme = "system"

    var colorSchemeFromSetting: ColorScheme? {
        switch appTheme {
        case "dark": return .dark
        case "light": return .light
        default: return nil
        }
    }

    init() {
        // Auto-load API key from Secrets.plist if not set
        if apiKey.isEmpty {
            if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path),
               let key = dict["GROQ_API_KEY"] as? String,
               !key.isEmpty {
                apiKey = key
                KeychainService.save(key: key)
            }
        }

        BackgroundTaskService.shared.registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading {
                    // Show splash while checking auth state
                    splashView
                } else if !authService.isSignedIn {
                    // Not signed in — show sign-in
                    SignInView()
                        .environmentObject(authService)
                } else if !hasOnboarded {
                    // Signed in but not onboarded — show profile setup
                    ProfileSetupView()
                        .environmentObject(authService)
                } else {
                    // Fully authenticated and onboarded
                    MainTabView()
                        .environment(\.managedObjectContext, persistence.container.viewContext)
                        .environmentObject(MeetingService.shared)
                        .environmentObject(TodoService.shared)
                        .environmentObject(authService)
                        .onOpenURL { url in
                            handleDeepLink(url)
                        }
                }
            }
            .preferredColorScheme(colorSchemeFromSetting)
        }
    }

    private var splashView: some View {
        ZStack {
            MMColors.background.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(MMColors.primary)
                ProgressView()
                    .tint(MMColors.primary)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let host = url.host else { return }
        switch host {
        case "record":
            NotificationCenter.default.post(name: .widgetStartRecording, object: nil)
        case "add-todo":
            NotificationCenter.default.post(name: .widgetAddTodo, object: nil)
        case "voice-todo":
            NotificationCenter.default.post(name: .widgetVoiceTodo, object: nil)
        case "todos":
            NotificationCenter.default.post(name: .widgetShowTodos, object: nil)
        default:
            break
        }
    }
}

// MARK: - Deep Link Notification Names

extension Notification.Name {
    static let widgetStartRecording = Notification.Name("widgetStartRecording")
    static let widgetAddTodo = Notification.Name("widgetAddTodo")
    static let widgetVoiceTodo = Notification.Name("widgetVoiceTodo")
    static let widgetShowTodos = Notification.Name("widgetShowTodos")
}
```

- [ ] **Step 2: Verify it compiles and the auth flow works**

Build and run in Simulator. Expected flow:
1. App launches → splash (brief) → SignInView appears
2. Tap "Continue without account" → ProfileSetupView appears
3. Complete all steps → MainTabView appears
4. Kill and relaunch → MainTabView appears directly (session persisted)

- [ ] **Step 3: Commit**

```bash
git add MeetMind/App/MeetMindApp.swift
git commit -m "feat: wire auth flow — sign-in → profile setup → main app"
```

---

### Task 7: Update SettingsView — Add Profile + Sign Out

**Files:**
- Modify: `MeetMind/Features/Settings/SettingsView.swift`

- [ ] **Step 1: Add user profile section to SettingsView**

At the top of the `SettingsView` struct, add the auth service:

```swift
@EnvironmentObject var authService: AuthService
```

Then add a new section at the top of the `VStack(spacing: 24)` inside `ScrollView`, before the "AI CONFIGURATION" section:

```swift
                    // MARK: - User Profile
                    settingsSection(header: "ACCOUNT") {
                        VStack(spacing: 0) {
                            // User info
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

                            // Sign out
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
```

- [ ] **Step 2: Add sign-out state and confirmation alert**

Add to the `@State` properties in SettingsView:

```swift
@State private var showSignOutConfirmation = false
```

Add the alert modifier after the existing `.sheet` modifiers on the NavigationStack:

```swift
.alert("Sign Out", isPresented: $showSignOutConfirmation) {
    Button("Sign Out", role: .destructive) {
        authService.signOut()
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("You'll need to sign in again to sync your data across devices.")
}
```

- [ ] **Step 3: Verify it compiles and sign-out works**

Build and run. Navigate to Settings tab. Verify:
- Profile photo, name, email, role visible at top
- "Sign Out" button is red
- Tapping sign out shows confirmation → returns to SignInView

- [ ] **Step 4: Commit**

```bash
git add MeetMind/Features/Settings/SettingsView.swift
git commit -m "feat: add account profile section + sign-out to SettingsView"
```

---

### Task 8: Clean Up Old OnboardingView

**Files:**
- Modify: `MeetMind/Features/Onboarding/OnboardingView.swift`

- [ ] **Step 1: Simplify OnboardingView as a redirect**

The old `OnboardingView` is no longer the primary entry point — `SignInView` and `ProfileSetupView` handle onboarding. Replace `OnboardingView.swift` to redirect to the new flow:

```swift
import SwiftUI

/// Legacy onboarding view — redirects to new auth-based flow.
/// Kept for backward compatibility with any existing references.
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasOnboarded = false

    var body: some View {
        ProfileSetupView()
            .environmentObject(AuthService.shared)
    }
}

#Preview {
    OnboardingView()
}
```

- [ ] **Step 2: Verify the app still launches correctly**

Build and run. The app should route through `MeetMindApp.swift`'s new auth flow, not through OnboardingView directly.

- [ ] **Step 3: Commit**

```bash
git add MeetMind/Features/Onboarding/OnboardingView.swift
git commit -m "refactor: simplify OnboardingView as redirect to new auth flow"
```

---

### Task 9: Inject AI Context from UserProfile into GroqService

**Files:**
- Modify: `MeetMind/Services/GroqService.swift`

- [ ] **Step 1: Find the system prompt in GroqService**

Open `MeetMind/Services/GroqService.swift` and find where the system prompt is constructed for meeting summaries (look for the chat completion call that generates briefs). It will have a system message string.

- [ ] **Step 2: Inject user profile context into the system prompt**

At the point where the system prompt is built, prepend the user profile context:

```swift
// Add at the top of the method that builds the summary prompt
let profileContext = UserProfile.load().aiContextString
let systemPrompt = """
\(profileContext)

\(existingSystemPromptContent)
"""
```

This ensures every AI call is personalized based on the user's role and work context.

- [ ] **Step 3: Verify meeting processing still works**

Record a short test meeting and process it. Verify the brief generates correctly with no errors.

- [ ] **Step 4: Commit**

```bash
git add MeetMind/Services/GroqService.swift
git commit -m "feat: inject UserProfile context into Groq AI prompts for personalized summaries"
```

---

### Task 10: Integration Test — Full Auth Flow

**Files:** None (manual testing)

- [ ] **Step 1: Test Google Sign-In flow**

1. Run on physical device (Google Sign-In requires a device or properly configured simulator)
2. Tap "Continue with Google"
3. Complete Google OAuth
4. Verify: ProfileSetupView appears

- [ ] **Step 2: Test profile setup flow**

1. Grant mic permission
2. Select a role (e.g., "Consultant")
3. Add description
4. Select tools (Teams, Google Meet)
5. Select frequency
6. Enter/skip API key
7. Verify: MainTabView appears

- [ ] **Step 3: Test session persistence**

1. Kill the app
2. Relaunch
3. Verify: MainTabView appears directly (no sign-in or onboarding)

- [ ] **Step 4: Test sign-out**

1. Go to Settings
2. Tap Sign Out → Confirm
3. Verify: SignInView appears
4. Verify: Can sign in again

- [ ] **Step 5: Test "Continue without account"**

1. From SignInView, tap "Continue without account"
2. Verify: ProfileSetupView appears
3. Complete setup
4. Verify: App works fully in local-only mode

- [ ] **Step 6: Update tracker**

Mark MM-109 through MM-113 as "done" in `tracker/tasks.json`.

- [ ] **Step 7: Final commit**

```bash
git add -A
git commit -m "feat: Phase 1 complete — Google Sign-In, onboarding, user profiling"
```
