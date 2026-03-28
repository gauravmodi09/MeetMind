import SwiftUI

struct EnhancedNotesView: View {
    let blocks: [EnhancedBlock]
    let onReEnhance: () -> Void
    @State private var selectedCitation: EnhancedBlock?
    @State private var isReEnhancing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(MMColors.primary)
                    .font(.system(size: 14))

                Text("Enhanced Notes")
                    .font(MMTypography.footnoteMedium)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                // Legend
                HStack(spacing: 12) {
                    legendDot(color: .white, label: "You")
                    legendDot(color: .white.opacity(0.45), label: "AI")
                }

                Button {
                    isReEnhancing = true
                    onReEnhance()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                        Text("Re-enhance")
                            .font(MMTypography.caption2)
                    }
                    .foregroundColor(MMColors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(MMColors.primary.opacity(0.12))
                    .cornerRadius(8)
                }
                .disabled(isReEnhancing)
            }
            .padding(16)

            Divider()
                .background(Color.white.opacity(0.06))

            // Enhanced blocks
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(blocks) { block in
                        HStack(alignment: .top, spacing: 8) {
                            Text(block.text)
                                .font(MMTypography.body)
                                .foregroundColor(block.isAI ? .white.opacity(0.45) : .white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if block.isAI && block.citationText != nil {
                                Button {
                                    selectedCitation = block
                                } label: {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 11))
                                        .foregroundColor(MMColors.primary.opacity(0.6))
                                        .frame(width: 24, height: 24)
                                        .background(MMColors.primary.opacity(0.08))
                                        .cornerRadius(6)
                                }
                                .accessibilityLabel("Show transcript source")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .sheet(item: $selectedCitation) { block in
            CitationView(block: block)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(MMTypography.caption2)
                .foregroundColor(.white.opacity(0.35))
        }
    }
}
