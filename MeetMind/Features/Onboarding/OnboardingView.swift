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
