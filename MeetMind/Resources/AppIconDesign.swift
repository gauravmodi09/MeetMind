import SwiftUI

/// MeetMind App Icon Design
/// Export this as a 1024x1024 image for App Store
/// Use Xcode's asset catalog or a screenshot tool to capture

struct AppIconView: View {
    var body: some View {
        ZStack {
            // Background gradient — deep purple to dark
            LinearGradient(
                colors: [
                    Color(red: 108/255, green: 92/255, blue: 231/255),   // #6C5CE7
                    Color(red: 75/255, green: 58/255, blue: 190/255),    // #4B3ABE
                    Color(red: 45/255, green: 32/255, blue: 140/255)     // #2D208C
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle radial glow behind the icon
            RadialGradient(
                colors: [
                    Color.white.opacity(0.15),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 350
            )

            // Icon content
            VStack(spacing: -8) {
                // Brain + waveform combined icon
                ZStack {
                    // Waveform bars behind brain
                    HStack(spacing: 6) {
                        ForEach([0.3, 0.6, 1.0, 0.7, 0.4], id: \.self) { height in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 6, height: 80 * height)
                        }
                    }

                    // Main brain icon
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 180, weight: .thin))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                }

                // "MM" text below
                Text("MM")
                    .font(.system(size: 80, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .kerning(-6)
            }
        }
        .frame(width: 1024, height: 1024)
        .clipShape(RoundedRectangle(cornerRadius: 224)) // iOS icon radius
    }
}

/// Alternative: Minimal mic + brain design
struct AppIconMinimalView: View {
    var body: some View {
        ZStack {
            // Solid purple background
            Color(red: 108/255, green: 92/255, blue: 231/255)

            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color.clear,
                    Color.black.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Combined mic + brain symbol
            ZStack {
                // Microphone
                Image(systemName: "mic.fill")
                    .font(.system(size: 280, weight: .regular))
                    .foregroundColor(.white)
                    .offset(x: -60)

                // Brain sparkle
                Image(systemName: "sparkles")
                    .font(.system(size: 120, weight: .bold))
                    .foregroundColor(Color(red: 255/255, green: 200/255, blue: 100/255))
                    .offset(x: 130, y: -120)
            }
        }
        .frame(width: 1024, height: 1024)
        .clipShape(RoundedRectangle(cornerRadius: 224))
    }
}

/// Alternative: Clean waveform + brain
struct AppIconWaveformView: View {
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 108/255, green: 92/255, blue: 231/255),
                    Color(red: 60/255, green: 45/255, blue: 170/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 20) {
                // Brain icon
                Image(systemName: "brain")
                    .font(.system(size: 250, weight: .light))
                    .foregroundColor(.white)

                // Waveform bars below
                HStack(spacing: 10) {
                    ForEach([0.25, 0.5, 0.8, 1.0, 0.8, 0.5, 0.25], id: \.self) { h in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 12, height: 100 * h)
                    }
                }
            }
        }
        .frame(width: 1024, height: 1024)
        .clipShape(RoundedRectangle(cornerRadius: 224))
    }
}

// MARK: - Previews

#Preview("Option A: Brain + MM") {
    AppIconView()
        .frame(width: 200, height: 200)
        .previewLayout(.sizeThatFits)
}

#Preview("Option B: Mic + Sparkle") {
    AppIconMinimalView()
        .frame(width: 200, height: 200)
        .previewLayout(.sizeThatFits)
}

#Preview("Option C: Brain + Waveform") {
    AppIconWaveformView()
        .frame(width: 200, height: 200)
        .previewLayout(.sizeThatFits)
}
