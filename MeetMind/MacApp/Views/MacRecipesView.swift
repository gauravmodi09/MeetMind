#if os(macOS)
import SwiftUI

// MARK: - MacRecipesView

struct MacRecipesView: View {
    @EnvironmentObject var meetingService: MeetingService
    @StateObject private var viewModel = MacRecipesViewModel()
    @State private var showCreateRecipe = false
    @State private var selectedRecipe: MeetingRecipe?
    @State private var showMeetingPicker = false
    @State private var hoveredRecipeId: UUID?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recipes")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(MMColors.textPrimary)
                    Text("AI-powered prompts applied to your meetings")
                        .font(.system(size: 12))
                        .foregroundColor(MMColors.textTertiary)
                }
                Spacer()

                Button {
                    showCreateRecipe = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Create Recipe")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(MMColors.primary)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Built-in Recipes Section
                    sectionHeader("Built-in", count: MeetingRecipe.builtIn.count)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(MeetingRecipe.builtIn) { recipe in
                            MacRecipeCard(
                                recipe: recipe,
                                isHovered: hoveredRecipeId == recipe.id
                            )
                            .onHover { hovered in
                                hoveredRecipeId = hovered ? recipe.id : nil
                            }
                            .onTapGesture {
                                selectedRecipe = recipe
                                showMeetingPicker = true
                            }
                        }
                    }

                    // Custom Recipes Section
                    if !viewModel.customRecipes.isEmpty {
                        sectionHeader("My Recipes", count: viewModel.customRecipes.count)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.customRecipes) { recipe in
                                MacRecipeCard(
                                    recipe: recipe,
                                    isHovered: hoveredRecipeId == recipe.id
                                )
                                .onHover { hovered in
                                    hoveredRecipeId = hovered ? recipe.id : nil
                                }
                                .onTapGesture {
                                    selectedRecipe = recipe
                                    showMeetingPicker = true
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        viewModel.deleteRecipe(recipe)
                                    } label: {
                                        Label("Delete Recipe", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(28)
            }
        }
        .background(MMColors.backgroundElevated)
        .sheet(isPresented: $showCreateRecipe) {
            MacCreateRecipeView(viewModel: viewModel)
        }
        .sheet(isPresented: $showMeetingPicker) {
            if let recipe = selectedRecipe {
                MacMeetingPickerForRecipe(
                    recipe: recipe,
                    meetings: meetingService.meetings.filter { $0.status == .complete }
                )
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(MMColors.textPrimary)
            Text("\(count)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(MMColors.textTertiary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(MMColors.border.opacity(0.5))
                )
            Spacer()
        }
    }
}

// MARK: - Recipe Card

struct MacRecipeCard: View {
    let recipe: MeetingRecipe
    let isHovered: Bool

    private var descriptionText: String {
        let trimmed = recipe.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(80)) + (trimmed.count > 80 ? "..." : "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                Image(systemName: recipe.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(MMColors.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(MMColors.primaryLight)
                    )
                Spacer()
                if recipe.isBuiltIn {
                    Text("Built-in")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(MMColors.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(MMColors.border.opacity(0.5))
                        )
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MMColors.textPrimary)
                    .lineLimit(2)

                Text(descriptionText)
                    .font(.system(size: 11))
                    .foregroundColor(MMColors.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(isHovered ? MMColors.primary : MMColors.border)
                    .animation(.easeInOut(duration: 0.15), value: isHovered)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovered ? MMColors.background : MMColors.cardBg)
                .shadow(
                    color: isHovered ? MMColors.shadowColor : MMColors.shadowColorLight,
                    radius: isHovered ? 8 : 2,
                    x: 0,
                    y: isHovered ? 4 : 1
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isHovered ? MMColors.primary.opacity(0.3) : MMColors.border,
                    lineWidth: isHovered ? 1.5 : 1
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Meeting Picker for Recipe

struct MacMeetingPickerForRecipe: View {
    let recipe: MeetingRecipe
    let meetings: [Meeting]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMeeting: Meeting?
    @State private var showResult = false
    @State private var hoveredMeetingId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center) {
                HStack(spacing: 10) {
                    Image(systemName: recipe.icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(MMColors.primary)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(MMColors.primaryLight)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(recipe.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(MMColors.textPrimary)
                        Text("Select a meeting to apply this recipe")
                            .font(.system(size: 11))
                            .foregroundColor(MMColors.textTertiary)
                    }
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(MMColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider()

            if meetings.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(meetings) { meeting in
                            meetingRow(meeting)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .frame(width: 480, height: 400)
        .background(MMColors.backgroundElevated)
        .sheet(isPresented: $showResult) {
            if let meeting = selectedMeeting {
                MacRecipeResultSheetView(recipe: recipe, meeting: meeting)
            }
        }
    }

    private func meetingRow(_ meeting: Meeting) -> some View {
        let isHovered = hoveredMeetingId == meeting.id

        return Button {
            selectedMeeting = meeting
            showResult = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(MMColors.primary.opacity(0.7))

                VStack(alignment: .leading, spacing: 3) {
                    Text(meeting.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(MMColors.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(meeting.date, style: .date)
                            .font(.system(size: 11))
                            .foregroundColor(MMColors.textTertiary)
                        if meeting.duration > 0 {
                            Text("·")
                                .font(.system(size: 11))
                                .foregroundColor(MMColors.textTertiary)
                            Text(formatDuration(meeting.duration))
                                .font(.system(size: 11))
                                .foregroundColor(MMColors.textTertiary)
                        }
                    }
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isHovered ? MMColors.primary : MMColors.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(isHovered ? MMColors.background : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { h in hoveredMeetingId = h ? meeting.id : nil }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(MMColors.textTertiary.opacity(0.5))
            Text("No completed meetings")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(MMColors.textSecondary)
            Text("Record and process a meeting first to apply recipes.")
                .font(.system(size: 12))
                .foregroundColor(MMColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 48)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}

// MARK: - Recipe Result Sheet (Mac)

struct MacRecipeResultSheetView: View {
    let recipe: MeetingRecipe
    let meeting: Meeting
    @Environment(\.dismiss) private var dismiss
    @State private var result = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var didCopy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: recipe.icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(MMColors.primary)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(MMColors.primaryLight)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(recipe.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(MMColors.textPrimary)
                    Text(meeting.title)
                        .font(.system(size: 11))
                        .foregroundColor(MMColors.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                if !isLoading && errorMessage == nil {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(result, forType: .string)
                        didCopy = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            didCopy = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11, weight: .medium))
                            Text(didCopy ? "Copied!" : "Copy")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(didCopy ? MMColors.success : MMColors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(MMColors.background)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7)
                                        .stroke(MMColors.border, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.2), value: didCopy)
                }

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(MMColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider()

            ZStack {
                MMColors.background.ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if let err = errorMessage {
                    errorView(err)
                } else {
                    resultScrollView
                }
            }
        }
        .frame(width: 600, height: 500)
        .background(MMColors.backgroundElevated)
        .task {
            await executeRecipe()
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .scaleEffect(1.1)
                .tint(MMColors.primary)
            Text("Applying \"\(recipe.name)\"...")
                .font(.system(size: 13))
                .foregroundColor(MMColors.textSecondary)
            Text(meeting.title)
                .font(.system(size: 11))
                .foregroundColor(MMColors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundColor(MMColors.warning)
            Text("Recipe Failed")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MMColors.textPrimary)
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(MMColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Try Again") {
                isLoading = true
                errorMessage = nil
                Task { await executeRecipe() }
            }
            .buttonStyle(.borderedProminent)
            .tint(MMColors.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Result

    private var resultScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Meeting context strip
                HStack(spacing: 10) {
                    Image(systemName: "waveform")
                        .font(.system(size: 13))
                        .foregroundColor(MMColors.primary)
                    Text(meeting.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MMColors.textPrimary)
                        .lineLimit(1)
                    Text("·")
                        .foregroundColor(MMColors.textTertiary)
                    Text(meeting.date, style: .date)
                        .font(.system(size: 11))
                        .foregroundColor(MMColors.textTertiary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(MMColors.cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(MMColors.border, lineWidth: 1)
                        )
                )

                // Result text
                Text(result)
                    .font(.system(size: 13))
                    .foregroundColor(MMColors.textSecondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(MMColors.cardBg)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(MMColors.border, lineWidth: 1)
                            )
                    )
            }
            .padding(20)
        }
    }

    // MARK: - Execution

    private func executeRecipe() async {
        guard let transcript = meeting.rawTranscript, !transcript.isEmpty else {
            errorMessage = "This meeting has no transcript available."
            isLoading = false
            return
        }
        do {
            result = try await GroqService.shared.executeRecipe(
                prompt: recipe.prompt,
                transcript: transcript
            )
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Create Recipe View (Mac)

struct MacCreateRecipeView: View {
    @ObservedObject var viewModel: MacRecipesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedIcon = "sparkles"
    @State private var prompt = ""

    private let iconOptions = [
        "sparkles", "brain.head.profile", "doc.text", "lightbulb.fill",
        "chart.bar", "person.2", "flag", "bolt.fill",
        "heart.fill", "star.fill", "trophy.fill", "book.fill"
    ]

    private let iconColumns = Array(repeating: GridItem(.fixed(44), spacing: 8), count: 6)

    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && !prompt.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Create Recipe")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(MMColors.textPrimary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(MMColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Name
                    fieldSection("Recipe Name") {
                        TextField("e.g., Summarize for CEO", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13))
                    }

                    // Icon Picker
                    fieldSection("Icon") {
                        LazyVGrid(columns: iconColumns, spacing: 8) {
                            ForEach(iconOptions, id: \.self) { iconName in
                                let isSelected = selectedIcon == iconName
                                Button {
                                    selectedIcon = iconName
                                } label: {
                                    Image(systemName: iconName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(isSelected ? .white : MMColors.primary)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: 9)
                                                .fill(isSelected ? MMColors.primary : MMColors.primaryLight)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 9)
                                                        .stroke(isSelected ? MMColors.primaryDark : Color.clear, lineWidth: 1.5)
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                                .animation(.easeInOut(duration: 0.12), value: isSelected)
                            }
                        }
                    }

                    // Prompt
                    fieldSection("Prompt") {
                        ZStack(alignment: .topLeading) {
                            if prompt.isEmpty {
                                Text("Describe what you want the AI to do with your meeting transcript…")
                                    .font(.system(size: 12))
                                    .foregroundColor(MMColors.textTertiary)
                                    .padding(.horizontal, 6)
                                    .padding(.top, 6)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $prompt)
                                .font(.system(size: 13))
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(MMColors.background)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(MMColors.border, lineWidth: 1)
                                )
                        )

                        Text("The prompt will be sent as a system instruction to the AI along with the meeting transcript.")
                            .font(.system(size: 11))
                            .foregroundColor(MMColors.textTertiary)
                    }
                }
                .padding(24)
            }

            Divider()

            // Footer buttons
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(MMColors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(MMColors.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(MMColors.border, lineWidth: 1)
                        )
                )

                Button("Save Recipe") {
                    let recipe = MeetingRecipe(
                        id: UUID(),
                        name: name.trimmingCharacters(in: .whitespaces),
                        icon: selectedIcon,
                        prompt: prompt.trimmingCharacters(in: .whitespaces),
                        isBuiltIn: false,
                        createdAt: Date()
                    )
                    viewModel.addRecipe(recipe)
                    dismiss()
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(canSave ? .white : MMColors.textTertiary)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(canSave ? MMColors.primary : MMColors.border)
                )
                .disabled(!canSave)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 500)
        .background(MMColors.backgroundElevated)
    }

    // MARK: - Field Section Helper

    @ViewBuilder
    private func fieldSection<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(MMColors.textTertiary)
                .textCase(.uppercase)
                .kerning(0.4)
            content()
        }
    }
}

// MARK: - ViewModel

@MainActor
class MacRecipesViewModel: ObservableObject {
    @Published var customRecipes: [MeetingRecipe] = []

    private let storageKey = "customMeetingRecipes"

    init() {
        loadRecipes()
    }

    func addRecipe(_ recipe: MeetingRecipe) {
        customRecipes.append(recipe)
        saveRecipes()
    }

    func deleteRecipe(_ recipe: MeetingRecipe) {
        customRecipes.removeAll { $0.id == recipe.id }
        saveRecipes()
    }

    private func loadRecipes() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        customRecipes = (try? JSONDecoder().decode([MeetingRecipe].self, from: data)) ?? []
    }

    private func saveRecipes() {
        if let data = try? JSONEncoder().encode(customRecipes) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

// MARK: - Preview

#Preview {
    MacRecipesView()
        .environmentObject(MeetingService.shared)
        .frame(width: 860, height: 640)
}
#endif
