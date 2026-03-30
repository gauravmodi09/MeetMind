import SwiftUI

// MARK: - MMButton

enum MMButtonStyle {
    case primary
    case secondary
    case ghost
}

struct MMButton: View {
    let title: String
    let icon: String?
    let style: MMButtonStyle
    let isLoading: Bool
    let action: () -> Void

    @State private var isPressed = false

    init(
        _ title: String,
        icon: String? = nil,
        style: MMButtonStyle = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            action()
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(textColor)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(MMTypography.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundColor(textColor)
            .background(backgroundColor)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: style == .secondary ? 1 : 0)
            )
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .disabled(isLoading)
    }

    private var textColor: Color {
        switch style {
        case .primary:   return .white
        case .secondary: return MMColors.primary
        case .ghost:     return MMColors.primary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:   return MMColors.primary
        case .secondary: return MMColors.glass
        case .ghost:     return .clear
        }
    }

    private var borderColor: Color {
        switch style {
        case .secondary: return MMColors.glassStroke
        default:         return .clear
        }
    }
}

// MARK: - MMCard

struct MMCard<Content: View>: View {
    let padding: CGFloat
    let content: () -> Content

    init(padding: CGFloat = 16, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background(MMColors.cardBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(MMColors.glassStroke, lineWidth: 1)
            )
            .shadow(color: MMColors.shadowColorLight, radius: 8, x: 0, y: 4)
            .shadow(color: MMColors.shadowColor, radius: 2, x: 0, y: 1)
    }
}

// MARK: - .mmCard() View Modifier

struct MMCardModifier: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(MMColors.cardBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(MMColors.glassStroke, lineWidth: 1)
            )
            .shadow(color: MMColors.shadowColorLight, radius: 8, x: 0, y: 4)
            .shadow(color: MMColors.shadowColor, radius: 2, x: 0, y: 1)
    }
}

extension View {
    func mmCard(padding: CGFloat = 16) -> some View {
        modifier(MMCardModifier(padding: padding))
    }
}

// MARK: - MMBadge

enum MMBadgeVariant {
    case priority(TodoPriority)
    case status(MeetingStatus)
    case client(String) // hex color
    case custom(Color, Color)
}

struct MMBadge: View {
    let text: String
    let variant: MMBadgeVariant

    var body: some View {
        Text(text)
            .font(MMTypography.caption2)
            .fontWeight(.semibold)
            .textCase(.uppercase)
            .tracking(0.3)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundColor(foregroundColor)
            .background(bgColor)
            .clipShape(Capsule())
    }

    private var foregroundColor: Color {
        switch variant {
        case .priority(let p):
            switch p {
            case .high:   return MMColors.recording
            case .medium: return MMColors.primary
            case .low:    return MMColors.textSecondary
            }
        case .status(let s):
            switch s {
            case .recording:  return MMColors.recording
            case .processing: return MMColors.warning
            case .complete:   return MMColors.success
            case .failed:     return MMColors.recording
            }
        case .client(let hex):
            return Color(hex: hex)
        case .custom(let fg, _):
            return fg
        }
    }

    private var bgColor: Color {
        switch variant {
        case .priority(let p):
            switch p {
            case .high:   return MMColors.recordingLight
            case .medium: return MMColors.primaryLight
            case .low:    return MMColors.glass
            }
        case .status(let s):
            switch s {
            case .recording:  return MMColors.recordingLight
            case .processing: return MMColors.warningLight
            case .complete:   return MMColors.successLight
            case .failed:     return MMColors.recordingLight
            }
        case .client(let hex):
            return Color(hex: hex).opacity(0.12)
        case .custom(_, let bg):
            return bg
        }
    }
}

// MARK: - MMTextField

struct MMTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .foregroundColor(isFocused ? MMColors.primary : MMColors.textTertiary)
                    .frame(width: 20)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
            }

            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(MMTypography.body)
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .font(MMTypography.body)
                    .focused($isFocused)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(MMColors.glass)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isFocused ? MMColors.primary : MMColors.glassStroke,
                    lineWidth: isFocused ? 1.5 : 1
                )
        )
        .shadow(
            color: isFocused ? MMColors.primaryGlow : .clear,
            radius: 8, x: 0, y: 0
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
}

// MARK: - MMEmptyState

struct MMEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [MMColors.primary.opacity(0.6), MMColors.textTertiary.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(spacing: 8) {
                Text(title)
                    .font(MMTypography.title3)
                    .foregroundColor(MMColors.textPrimary)

                Text(message)
                    .font(MMTypography.subheadline)
                    .foregroundColor(MMColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }

            if let buttonTitle, let buttonAction {
                MMButton(buttonTitle, style: .secondary, action: buttonAction)
                    .frame(width: 200)
                    .padding(.top, 4)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#Preview("Buttons") {
    VStack(spacing: 16) {
        MMButton("Start Recording", icon: "mic.fill", action: {})
        MMButton("View Summary", style: .secondary, action: {})
        MMButton("Cancel", style: .ghost, action: {})
        MMButton("Processing...", isLoading: true, action: {})
    }
    .padding()
    .background(MMColors.background)
}

#Preview("Cards") {
    VStack(spacing: 16) {
        MMCard {
            Text("Glassmorphism Card")
                .font(MMTypography.headline)
                .foregroundColor(MMColors.textPrimary)
        }

        Text("Using .mmCard() modifier")
            .font(MMTypography.body)
            .foregroundColor(MMColors.textPrimary)
            .mmCard()
    }
    .padding()
    .background(MMColors.background)
}

#Preview("Badges") {
    HStack(spacing: 8) {
        MMBadge(text: "High", variant: .priority(.high))
        MMBadge(text: "Medium", variant: .priority(.medium))
        MMBadge(text: "Low", variant: .priority(.low))
        MMBadge(text: "Recording", variant: .status(.recording))
        MMBadge(text: "Acme Corp", variant: .client("6C5CE7"))
    }
    .padding()
    .background(MMColors.background)
}

#Preview("Empty State") {
    MMEmptyState(
        icon: "mic.slash",
        title: "No meetings yet",
        message: "Tap the mic button to record your first meeting.",
        buttonTitle: "Record Meeting",
        buttonAction: {}
    )
    .background(MMColors.background)
}
