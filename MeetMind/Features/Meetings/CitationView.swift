import SwiftUI

struct CitationView: View {
    let block: EnhancedBlock
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "quote.opening")
                    .foregroundColor(MMColors.primary)
                    .font(.system(size: 16))
                Text("Transcript Source")
                    .font(MMTypography.headline)
                    .foregroundColor(.white)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            VStack(alignment: .leading, spacing: 8) {
                Text("AI-Enhanced Text")
                    .font(MMTypography.caption1Medium)
                    .foregroundColor(.white.opacity(0.4))
                Text(block.text)
                    .font(MMTypography.body)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal, 20)

            if let range = block.citationRange {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(MMColors.primary)
                    Text(range)
                        .font(MMTypography.monoSmall)
                        .foregroundColor(MMColors.primary)
                }
                .padding(.horizontal, 20)
            }

            if let citation = block.citationText {
                VStack(alignment: .leading, spacing: 8) {
                    Text("From Transcript")
                        .font(MMTypography.caption1Medium)
                        .foregroundColor(.white.opacity(0.4))
                    Text(citation)
                        .font(MMTypography.body)
                        .foregroundColor(.white)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(MMColors.primary.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(MMColors.primary.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
        .background(Color(hex: "0A0A0F"))
    }
}
