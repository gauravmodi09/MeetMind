import SwiftUI

struct MMTypography {
    // MARK: - Display (Hero elements)
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title1 = Font.system(size: 28, weight: .bold, design: .default)
    static let title2 = Font.system(size: 22, weight: .bold, design: .default)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)

    // MARK: - Body
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 17, weight: .regular)
    static let bodyMedium = Font.system(size: 17, weight: .medium)
    static let subheadline = Font.system(size: 15, weight: .regular)
    static let subheadlineMedium = Font.system(size: 15, weight: .medium)

    // MARK: - Small
    static let footnote = Font.system(size: 13, weight: .regular)
    static let footnoteMedium = Font.system(size: 13, weight: .medium)
    static let caption1 = Font.system(size: 12, weight: .regular)
    static let caption1Medium = Font.system(size: 12, weight: .medium)
    static let caption2 = Font.system(size: 11, weight: .regular)

    // MARK: - Mono (timers, data)
    static let monoLarge = Font.system(size: 48, weight: .light, design: .monospaced)
    static let monoMedium = Font.system(size: 20, weight: .medium, design: .monospaced)
    static let monoSmall = Font.system(size: 13, weight: .regular, design: .monospaced)

    // MARK: - Overline (section labels)
    static let overline = Font.system(size: 11, weight: .semibold)

    // MARK: - Legacy Aliases
    static let mono = Font.system(size: 15, weight: .medium, design: .monospaced)
}
