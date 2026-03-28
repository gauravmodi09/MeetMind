import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isAnimating = false

    var body: some View {
        ZStack {
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

                VStack(spacing: 12) {
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
