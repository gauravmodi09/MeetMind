import SwiftUI

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            Color.white.opacity(0.4),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.6)
                    .offset(x: -geometry.size.width * 0.6 + phase * (geometry.size.width * 1.6))
                    .clipped()
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.4)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Shimmer Block

struct ShimmerBlock: View {
    let height: CGFloat
    var widthFraction: CGFloat = 1.0
    var cornerRadius: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(MMColors.border.opacity(0.4))
                .frame(width: geometry.size.width * widthFraction, height: height)
                .shimmer()
        }
        .frame(height: height)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ShimmerBlock(height: 20, widthFraction: 0.6)
        ShimmerBlock(height: 80)
        ShimmerBlock(height: 14, widthFraction: 0.9)
        ShimmerBlock(height: 14, widthFraction: 0.9)
        ShimmerBlock(height: 14, widthFraction: 0.9)
        ShimmerBlock(height: 50)
        ShimmerBlock(height: 50)
    }
    .padding()
}
