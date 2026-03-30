import SwiftUI

/// MeetMind App Icon — Buddy Style
/// A friendly, warm app icon with a character feel

struct AppIconView: View {
    var body: some View {
        ZStack {
            // Warm purple gradient background
            LinearGradient(
                colors: [
                    Color(red: 124/255, green: 104/255, blue: 238/255),  // Soft purple
                    Color(red: 88/255, green: 70/255, blue: 210/255),    // Mid purple
                    Color(red: 60/255, green: 42/255, blue: 170/255)     // Deep purple
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 80,
                        endRadius: 400
                    )
                )
                .offset(y: -60)

            // Main buddy character
            VStack(spacing: 0) {
                // Buddy face — a friendly rounded shape with eyes
                ZStack {
                    // Head/body — rounded blob
                    RoundedRectangle(cornerRadius: 120)
                        .fill(Color.white)
                        .frame(width: 520, height: 480)
                        .shadow(color: Color.black.opacity(0.1), radius: 20, y: 10)

                    // Face content
                    VStack(spacing: 30) {
                        // Eyes — friendly dots
                        HStack(spacing: 100) {
                            // Left eye
                            ZStack {
                                Circle()
                                    .fill(Color(red: 60/255, green: 42/255, blue: 170/255))
                                    .frame(width: 70, height: 70)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 22, height: 22)
                                    .offset(x: 10, y: -10)
                            }

                            // Right eye
                            ZStack {
                                Circle()
                                    .fill(Color(red: 60/255, green: 42/255, blue: 170/255))
                                    .frame(width: 70, height: 70)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 22, height: 22)
                                    .offset(x: 10, y: -10)
                            }
                        }

                        // Smile — friendly curved line
                        Capsule()
                            .fill(Color(red: 60/255, green: 42/255, blue: 170/255).opacity(0.8))
                            .frame(width: 120, height: 24)
                            .offset(y: -5)
                    }
                    .offset(y: 10)

                    // Headphones — the meeting recording element
                    // Left ear
                    ZStack {
                        Circle()
                            .fill(Color(red: 108/255, green: 92/255, blue: 231/255))
                            .frame(width: 80, height: 80)
                        Circle()
                            .fill(Color(red: 88/255, green: 70/255, blue: 210/255))
                            .frame(width: 56, height: 56)
                    }
                    .offset(x: -250, y: -20)

                    // Right ear
                    ZStack {
                        Circle()
                            .fill(Color(red: 108/255, green: 92/255, blue: 231/255))
                            .frame(width: 80, height: 80)
                        Circle()
                            .fill(Color(red: 88/255, green: 70/255, blue: 210/255))
                            .frame(width: 56, height: 56)
                    }
                    .offset(x: 250, y: -20)

                    // Headband arc (simplified as a thick capsule)
                    Capsule()
                        .fill(Color(red: 108/255, green: 92/255, blue: 231/255))
                        .frame(width: 440, height: 28)
                        .offset(y: -230)

                    // Mic boom from left headphone
                    ZStack {
                        // Boom arm
                        Capsule()
                            .fill(Color(red: 88/255, green: 70/255, blue: 210/255))
                            .frame(width: 8, height: 100)
                            .rotationEffect(.degrees(30))

                        // Mic head
                        Circle()
                            .fill(Color(red: 255/255, green: 100/255, blue: 100/255))
                            .frame(width: 40, height: 40)
                            .offset(x: 30, y: 50)
                    }
                    .offset(x: -210, y: 80)

                    // AI sparkle on forehead
                    Image(systemName: "sparkle")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(Color(red: 255/255, green: 210/255, blue: 80/255))
                        .offset(x: 140, y: -180)
                }
            }
        }
        .frame(width: 1024, height: 1024)
        .clipShape(RoundedRectangle(cornerRadius: 224))
    }
}

/// Alternative: Clean modern icon (non-buddy)
struct AppIconCleanView: View {
    var body: some View {
        ZStack {
            // Purple gradient
            LinearGradient(
                colors: [
                    Color(red: 124/255, green: 104/255, blue: 238/255),
                    Color(red: 60/255, green: 42/255, blue: 170/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Glow
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 500, height: 500)
                .offset(y: -100)

            // Friendly mic with brain waves
            VStack(spacing: -20) {
                ZStack {
                    // Sound waves
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color.white.opacity(0.15 - Double(i) * 0.04), lineWidth: 4)
                            .frame(width: CGFloat(300 + i * 120), height: CGFloat(300 + i * 120))
                    }

                    // Central mic icon
                    Image(systemName: "mic.fill")
                        .font(.system(size: 260, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                // Brain sparkle
                HStack(spacing: 8) {
                    Image(systemName: "brain")
                        .font(.system(size: 50))
                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                }
                .foregroundColor(Color(red: 255/255, green: 210/255, blue: 80/255))
                .offset(y: 20)
            }
        }
        .frame(width: 1024, height: 1024)
        .clipShape(RoundedRectangle(cornerRadius: 224))
    }
}

// MARK: - PNG Generator

struct AppIconGenerator {
    @MainActor
    static func generateIcon() {
        let renderer = ImageRenderer(content: AppIconView().frame(width: 1024, height: 1024))
        renderer.scale = 1.0

        #if os(iOS)
        if let image = renderer.uiImage,
           let data = image.pngData() {
            let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = docsURL.appendingPathComponent("MeetMindAppIcon.png")
            try? data.write(to: fileURL)
            print("[AppIcon] Saved to: \(fileURL.path)")
        }
        #endif
    }
}

#Preview("Buddy Icon") {
    AppIconView()
        .frame(width: 300, height: 300)
}

#Preview("Clean Icon") {
    AppIconCleanView()
        .frame(width: 300, height: 300)
}
