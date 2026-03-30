import SwiftUI

struct MMColors {
    // MARK: - Brand
    static let primary = Color(hex: "6C5CE7")
    static let primaryLight = Color(hex: "EDE9FE")
    static let primaryDark = Color(hex: "5A4BD6")
    static let primaryGlow = Color(hex: "6C5CE7").opacity(0.15)

    // MARK: - Semantic
    static let success = Color(hex: "10B981")
    static let successLight = Color(hex: "D1FAE5")
    static let recording = Color(hex: "EF4444")
    static let recordingLight = Color(hex: "FEE2E2")
    static let warning = Color(hex: "F59E0B")
    static let warningLight = Color(hex: "FEF3C7")
    static let info = Color(hex: "3B82F6")
    static let infoLight = Color(hex: "DBEAFE")

    // MARK: - Surfaces (Clean Light Mode)
    static let background = Color(hex: "F9FAFB")
    static let backgroundElevated = Color(hex: "FFFFFF")
    static let cardBg = Color(hex: "FFFFFF")
    static let cardBgElevated = Color(hex: "FFFFFF")

    // MARK: - Text
    static let textPrimary = Color(hex: "111827")
    static let textSecondary = Color(hex: "4B5563")
    static let textTertiary = Color(hex: "9CA3AF")

    // MARK: - Borders & Dividers
    static let border = Color(hex: "E5E7EB")
    static let borderSubtle = Color(hex: "F3F4F6")
    static let divider = Color(hex: "F3F4F6")

    // MARK: - Glass
    static let glass = Color.white.opacity(0.6)
    static let glassStroke = Color.white.opacity(0.8)

    // MARK: - Shadows
    static let shadowColor = Color.black.opacity(0.08)
    static let shadowColorLight = Color.black.opacity(0.04)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }

    init(light: String, dark: String) {
        // Enforce light mode for everything per new design spec
        self.init(hex: light)
    }
}

/// Animated floating orbs that create a premium, clean ambiance behind content
struct AnimatedMeshBackground: View {
    @State private var animateBlobs = false

    var body: some View {
        ZStack {
            // Clean airy base
            Color(hex: "F9FAFB")
                .ignoresSafeArea()

            // Large primary purple orb — top right
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "6C5CE7").opacity(0.12),
                            Color(hex: "6C5CE7").opacity(0.03),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 180
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: animateBlobs ? 100 : 120, y: animateBlobs ? -280 : -250)
                .blur(radius: 40)

            // Teal accent orb — bottom left
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "10B981").opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .offset(x: animateBlobs ? -130 : -110, y: animateBlobs ? 300 : 350)
                .blur(radius: 40)

            // Blue accent orb — mid left
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "3B82F6").opacity(0.06),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .offset(x: animateBlobs ? -80 : -50, y: animateBlobs ? -50 : -20)
                .blur(radius: 30)

            // Warm accent orb — center bottom
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "F59E0B").opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .offset(x: animateBlobs ? 60 : 40, y: animateBlobs ? 150 : 180)
                .blur(radius: 25)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true)
            ) {
                animateBlobs = true
            }
        }
    }
}

/// Glassmorphic card background modifier
struct GlassmorphicCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .light)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.8),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func glassmorphic(cornerRadius: CGFloat = 20, padding: CGFloat = 16) -> some View {
        modifier(GlassmorphicCard(cornerRadius: cornerRadius, padding: padding))
    }
}



// MARK: - Preview

#Preview {
    ZStack {
        AnimatedMeshBackground()
        VStack(spacing: 20) {
            Text("Premium Glass Card")
                .font(.title2.bold())
                .foregroundColor(.white)
                .glassmorphic()

            Text("Shimmer Effect")
                .font(.title3.bold())
                .foregroundColor(.white)
                .shimmer()
        }
    }
}
