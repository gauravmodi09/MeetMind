#if os(macOS)
import SwiftUI

enum MacSection: String, CaseIterable, Identifiable {
    case meetings
    case todos
    case notes
    case library
    case chat
    case settings

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .meetings: return "waveform.circle.fill"
        case .todos:    return "checkmark.circle.fill"
        case .notes:    return "note.text"
        case .library:  return "books.vertical.fill"
        case .chat:     return "bubble.left.and.bubble.right.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var label: String {
        switch self {
        case .meetings: return "Meetings"
        case .todos:    return "Todos"
        case .notes:    return "Notes"
        case .library:  return "Library"
        case .chat:     return "Chat"
        case .settings: return "Settings"
        }
    }
}

struct MacIconRail: View {
    @Binding var activeSection: MacSection
    var isRecording: Bool = false

    private let railWidth: CGFloat = 56
    private let railBackground = Color(red: 0.102, green: 0.102, blue: 0.180) // #1a1a2e

    var body: some View {
        VStack(spacing: 6) {
            // App icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isRecording ? Color.red : MMColors.primary)
                    .frame(width: 32, height: 32)
                Image(systemName: isRecording ? "stop.fill" : "waveform.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 12)

            // Main nav items (exclude settings)
            ForEach(MacSection.allCases.filter { $0 != .settings }) { section in
                railButton(for: section)
            }

            Spacer()

            // Settings pinned to bottom
            railButton(for: .settings)
        }
        .padding(.vertical, 16)
        .frame(width: railWidth)
        .background(railBackground)
    }

    private func railButton(for section: MacSection) -> some View {
        Button {
            activeSection = section
        } label: {
            VStack(spacing: 2) {
                Image(systemName: section.icon)
                    .font(.system(size: 14))
                Text(section.label)
                    .font(.system(size: 8))
            }
            .frame(width: 36, height: 36)
            .foregroundColor(activeSection == section ? .white : .white.opacity(0.4))
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(activeSection == section
                          ? MMColors.primary.opacity(0.25)
                          : Color.white.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }
}
#endif
