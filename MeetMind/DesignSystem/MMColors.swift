import SwiftUI
import UIKit

struct MMColors {
    // MARK: - Brand
    static let primary = Color(hex: "6C5CE7")
    static let primaryLight = Color(light: "ede9fe", dark: "2D2654")
    static let primaryDark = Color(hex: "5A4BD6")
    static let primaryGlow = Color(hex: "6C5CE7").opacity(0.2)

    // MARK: - Semantic
    static let success = Color(hex: "00CE9E")
    static let successLight = Color(light: "e6faf5", dark: "0D3D30")
    static let recording = Color(hex: "FF4757")
    static let recordingLight = Color(light: "ffeaec", dark: "3D1520")
    static let warning = Color(hex: "FFA502")
    static let warningLight = Color(light: "fff5e6", dark: "3D2E10")
    static let info = Color(hex: "2D98FF")
    static let infoLight = Color(light: "eaf4ff", dark: "102840")

    // MARK: - Surfaces (Cinema Dark)
    static let background = Color(light: "F8F7FC", dark: "0A0A0F")
    static let backgroundElevated = Color(light: "FFFFFF", dark: "12121A")
    static let cardBg = Color(light: "FFFFFF", dark: "16161F")
    static let cardBgElevated = Color(light: "FFFFFF", dark: "1C1C28")

    // MARK: - Text
    static let textPrimary = Color(light: "1A1A2E", dark: "EDEDEF")
    static let textSecondary = Color(light: "6B7280", dark: "8A8F98")
    static let textTertiary = Color(light: "9CA3AF", dark: "555962")

    // MARK: - Borders & Dividers
    static let border = Color(light: "E5E7EB", dark: "FFFFFF").opacity(0.08)
    static let borderSubtle = Color(light: "F3F4F6", dark: "FFFFFF").opacity(0.04)
    static let divider = Color(light: "F3F4F6", dark: "FFFFFF").opacity(0.06)

    // MARK: - Glass
    static let glass = Color.white.opacity(0.05)
    static let glassStroke = Color.white.opacity(0.08)

    // MARK: - Shadows
    static let shadowColor = Color.black.opacity(0.15)
    static let shadowColorLight = Color.black.opacity(0.06)
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
        self.init(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        })
    }
}
