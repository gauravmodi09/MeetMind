import SwiftUI

/// A compact sentiment indicator for use in meeting cards and detail views.
/// Shows a colored circle with a sentiment label.
struct SentimentIndicator: View {
    let score: Double
    let showLabel: Bool

    init(score: Double, showLabel: Bool = true) {
        self.score = score
        self.showLabel = showLabel
    }

    private var sentimentColor: Color {
        if score > 0.2 { return MMColors.success }
        if score < -0.2 { return MMColors.recording }
        return MMColors.warning
    }

    private var sentimentLabel: String {
        if score > 0.2 { return "Positive" }
        if score < -0.2 { return "Negative" }
        return "Neutral"
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(sentimentColor)
                .frame(width: 8, height: 8)

            if showLabel {
                Text(sentimentLabel)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(sentimentColor)
            }
        }
    }
}

#Preview("Positive") {
    SentimentIndicator(score: 0.6)
        .padding()
        .background(MMColors.cardBg)
}

#Preview("Neutral") {
    SentimentIndicator(score: 0.0)
        .padding()
        .background(MMColors.cardBg)
}

#Preview("Negative") {
    SentimentIndicator(score: -0.5)
        .padding()
        .background(MMColors.cardBg)
}

#Preview("No Label") {
    SentimentIndicator(score: 0.8, showLabel: false)
        .padding()
        .background(MMColors.cardBg)
}
