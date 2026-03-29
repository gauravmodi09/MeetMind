import SwiftUI

// MARK: - Notification for audio seek

extension Notification.Name {
    static let seekAudioToTime = Notification.Name("seekAudioToTime")
}

// MARK: - AudioHighlightsView

struct AudioHighlightsView: View {
    let highlights: [AudioHighlight]

    @State private var selectedCategory: HighlightCategory?

    private var filteredHighlights: [AudioHighlight] {
        guard let category = selectedCategory else { return highlights }
        return highlights.filter { $0.category == category }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            categoryFilter
            if filteredHighlights.isEmpty {
                emptyState
            } else {
                timelineList
            }
        }
        .padding(16)
        .background(MMColors.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(MMColors.primary)

            Text("Key Moments")
                .font(MMTypography.title3)
                .foregroundStyle(MMColors.textPrimary)

            Spacer()

            Text("\(filteredHighlights.count)")
                .font(MMTypography.caption1Medium)
                .foregroundStyle(MMColors.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(MMColors.primaryLight)
                .clipShape(Capsule())
        }
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "All", category: nil, count: highlights.count)
                ForEach(HighlightCategory.allCases, id: \.self) { cat in
                    let count = highlights.filter { $0.category == cat }.count
                    if count > 0 {
                        filterChip(label: cat.rawValue, category: cat, count: count)
                    }
                }
            }
        }
    }

    private func filterChip(label: String, category: HighlightCategory?, count: Int) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: 4) {
                if let cat = category {
                    Image(systemName: cat.icon)
                        .font(.system(size: 11))
                }
                Text(label)
                    .font(MMTypography.caption1Medium)
                Text("\(count)")
                    .font(MMTypography.caption2)
                    .foregroundStyle(isSelected ? MMColors.primary : MMColors.textTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundStyle(isSelected ? MMColors.primary : MMColors.textSecondary)
            .background(isSelected ? MMColors.primaryLight : MMColors.cardBgElevated)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? MMColors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Timeline

    private var timelineList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(filteredHighlights.enumerated()), id: \.element.id) { index, highlight in
                highlightRow(highlight, isLast: index == filteredHighlights.count - 1)
            }
        }
    }

    private func highlightRow(_ highlight: AudioHighlight, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline column
            VStack(spacing: 0) {
                categoryDot(highlight.category)
                if !isLast {
                    Rectangle()
                        .fill(MMColors.border)
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 28)

            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    // Tappable timestamp
                    Button {
                        NotificationCenter.default.post(
                            name: .seekAudioToTime,
                            object: nil,
                            userInfo: ["time": highlight.timestamp]
                        )
                    } label: {
                        Text(highlight.formattedTimestamp)
                            .font(MMTypography.monoSmall)
                            .foregroundStyle(MMColors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(MMColors.primaryLight)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)

                    categoryLabel(highlight.category)
                }

                Text(highlight.text)
                    .font(MMTypography.subheadline)
                    .foregroundStyle(MMColors.textPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? 0 : 16)
        }
    }

    private func categoryDot(_ category: HighlightCategory) -> some View {
        ZStack {
            Circle()
                .fill(categoryColor(category).opacity(0.15))
                .frame(width: 28, height: 28)

            Image(systemName: category.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(categoryColor(category))
        }
    }

    private func categoryLabel(_ category: HighlightCategory) -> some View {
        Text(category.rawValue)
            .font(MMTypography.caption2)
            .foregroundStyle(categoryColor(category))
    }

    private func categoryColor(_ category: HighlightCategory) -> Color {
        switch category {
        case .decision:  return MMColors.success
        case .action:    return MMColors.warning
        case .question:  return MMColors.info
        case .keyQuote:  return MMColors.primary
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.badge.magnifyingglass")
                .font(.system(size: 28))
                .foregroundStyle(MMColors.textTertiary)
            Text("No key moments found")
                .font(MMTypography.footnote)
                .foregroundStyle(MMColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - Preview

#Preview {
    let sampleHighlights: [AudioHighlight] = [
        AudioHighlight(timestamp: 42, text: "We've decided to go with the new API architecture for the backend migration.", category: .decision),
        AudioHighlight(timestamp: 125, text: "I'll have the design mockups ready by Friday for the team review.", category: .action),
        AudioHighlight(timestamp: 203, text: "What's the timeline for getting the staging environment set up?", category: .question),
        AudioHighlight(timestamp: 340, text: "Sarah will handle the client onboarding documentation before next sprint.", category: .action),
        AudioHighlight(timestamp: 410, text: "We agreed to move the launch date to March 15th to allow for more testing.", category: .decision),
    ]

    ScrollView {
        AudioHighlightsView(highlights: sampleHighlights)
            .padding()
    }
    .background(MMColors.background)
}
