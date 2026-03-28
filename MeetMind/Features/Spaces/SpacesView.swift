import SwiftUI

struct SpacesView: View {
    @StateObject private var spaceService = SpaceService.shared
    @EnvironmentObject var meetingService: MeetingService
    @State private var showCreateSheet = false
    @State private var selectedSpace: Space?

    var body: some View {
        NavigationStack {
            ZStack {
                MMColors.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(spaceService.spaces) { space in
                            spaceCard(space)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Spaces")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(MMColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateSpaceSheet { space in
                    spaceService.addSpace(space)
                }
            }
            .navigationDestination(item: $selectedSpace) { space in
                SpaceDetailView(space: space)
            }
        }
    }

    private func spaceCard(_ space: Space) -> some View {
        Button {
            selectedSpace = space
        } label: {
            HStack(spacing: 14) {
                Image(systemName: space.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color(hex: space.colorHex))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(space.name)
                        .font(MMTypography.headline)
                        .foregroundColor(MMColors.textPrimary)

                    let count = meetingsInSpace(space).count
                    Text("\(count) meeting\(count == 1 ? "" : "s")")
                        .font(MMTypography.caption1)
                        .foregroundColor(MMColors.textTertiary)
                }

                Spacer()

                if !space.isDefault {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MMColors.textTertiary)
                }
            }
            .padding(14)
            .background(MMColors.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(MMColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !space.isDefault {
                Button(role: .destructive) {
                    spaceService.deleteSpace(space)
                } label: {
                    Label("Delete Space", systemImage: "trash")
                }
            }
        }
    }

    private func meetingsInSpace(_ space: Space) -> [Meeting] {
        if space.isDefault {
            return meetingService.meetings
        }
        return meetingService.meetings.filter { space.meetingIds.contains($0.id) }
    }
}

// MARK: - Space Detail View

struct SpaceDetailView: View {
    let space: Space
    @EnvironmentObject var meetingService: MeetingService
    @StateObject private var spaceService = SpaceService.shared

    var meetings: [Meeting] {
        if space.isDefault {
            return meetingService.meetings
        }
        return meetingService.meetings.filter { space.meetingIds.contains($0.id) }
    }

    var body: some View {
        ZStack {
            MMColors.background.ignoresSafeArea()

            if meetings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: space.icon)
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: space.colorHex).opacity(0.5))
                    Text("No meetings yet")
                        .font(MMTypography.headline)
                        .foregroundColor(MMColors.textSecondary)
                    Text("Meetings added to this space will appear here.")
                        .font(MMTypography.subheadline)
                        .foregroundColor(MMColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(meetings) { meeting in
                            NavigationLink(value: meeting) {
                                MeetingCard(meeting: meeting, onCopy: {}, onDelete: {})
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle(space.name)
        .navigationDestination(for: Meeting.self) { meeting in
            MeetingDetailView(meeting: meeting)
        }
    }
}

// MARK: - Create Space Sheet

struct CreateSpaceSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onCreate: (Space) -> Void

    @State private var name = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColor = "6C5CE7"

    private let icons = ["folder.fill", "star.fill", "briefcase.fill", "person.2.fill", "lightbulb.fill", "chart.bar.fill", "gear", "tag.fill", "flag.fill", "heart.fill", "book.fill", "globe"]
    private let colors = ["6C5CE7", "FF6B6B", "4ECDC4", "FFE66D", "A8E6CF", "FF8A5C", "6C7A89", "D4A5FF", "5B86E5", "FF4081"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Space name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 18))
                                    .frame(width: 40, height: 40)
                                    .background(selectedIcon == icon ? Color(hex: selectedColor) : MMColors.cardBg)
                                    .foregroundColor(selectedIcon == icon ? .white : MMColors.textSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Space")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let space = Space(name: name, icon: selectedIcon, colorHex: selectedColor)
                        onCreate(space)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
