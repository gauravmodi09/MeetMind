import SwiftUI

struct BriefLoadingView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title bar
            ShimmerBlock(height: 20, widthFraction: 0.6, cornerRadius: 6)

            // Summary block
            ShimmerBlock(height: 80, cornerRadius: 10)

            // Decisions section
            VStack(alignment: .leading, spacing: 10) {
                ShimmerBlock(height: 12, widthFraction: 0.3, cornerRadius: 4)
                    .padding(.bottom, 4)
                ShimmerBlock(height: 14, widthFraction: 0.9, cornerRadius: 4)
                ShimmerBlock(height: 14, widthFraction: 0.9, cornerRadius: 4)
                ShimmerBlock(height: 14, widthFraction: 0.9, cornerRadius: 4)
            }

            // Action items section
            VStack(alignment: .leading, spacing: 10) {
                ShimmerBlock(height: 12, widthFraction: 0.35, cornerRadius: 4)
                    .padding(.bottom, 4)
                ShimmerBlock(height: 50, cornerRadius: 10)
                ShimmerBlock(height: 50, cornerRadius: 10)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(MMColors.cardBg)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        MMColors.background.ignoresSafeArea()
        BriefLoadingView()
    }
}
