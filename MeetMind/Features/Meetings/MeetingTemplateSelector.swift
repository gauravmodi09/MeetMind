import SwiftUI

struct MeetingTemplateSelector: View {
    @Binding var selectedTemplate: MeetingTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "rectangle.grid.1x2")
                    .font(.system(size: 12))
                    .foregroundColor(MMColors.primary)

                Text("Meeting Type")
                    .font(MMTypography.caption1)
                    .foregroundColor(MMColors.textTertiary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MeetingTemplate.allCases, id: \.self) { template in
                        templatePill(template)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func templatePill(_ template: MeetingTemplate) -> some View {
        let isSelected = selectedTemplate == template

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTemplate = template
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: template.icon)
                    .font(.system(size: 12, weight: .medium))

                Text(template.rawValue)
                    .font(MMTypography.footnoteMedium)
            }
            .foregroundColor(isSelected ? .white : MMColors.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? MMColors.primary
                    : MMColors.cardBg
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? MMColors.primary : MMColors.border,
                        lineWidth: 1
                    )
            )
        }
        .accessibilityLabel("\(template.rawValue) meeting type")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Double-tap to select this meeting type")
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        MMColors.background.ignoresSafeArea()

        MeetingTemplateSelector(selectedTemplate: .constant(.general))
            .padding()
    }
}
