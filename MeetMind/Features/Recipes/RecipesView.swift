import SwiftUI

struct RecipesView: View {
    @EnvironmentObject var meetingService: MeetingService
    @StateObject private var viewModel = RecipesViewModel()
    @State private var showCreateRecipe = false
    @State private var selectedRecipe: MeetingRecipe?
    @State private var showMeetingPicker = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Built-in Recipes
                    sectionHeader("Built-in", count: MeetingRecipe.builtIn.count)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(MeetingRecipe.builtIn) { recipe in
                            RecipeCard(recipe: recipe)
                                .onTapGesture {
                                    selectedRecipe = recipe
                                    showMeetingPicker = true
                                }
                        }
                    }

                    // My Recipes
                    if !viewModel.customRecipes.isEmpty {
                        sectionHeader("My Recipes", count: viewModel.customRecipes.count)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.customRecipes) { recipe in
                                RecipeCard(recipe: recipe)
                                    .onTapGesture {
                                        selectedRecipe = recipe
                                        showMeetingPicker = true
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            viewModel.deleteRecipe(recipe)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(MMColors.background)
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: {
                    #if os(iOS)
                    return .navigationBarTrailing
                    #else
                    return .automatic
                    #endif
                }()) {
                    Button {
                        showCreateRecipe = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(MMColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showCreateRecipe) {
                CreateRecipeView(viewModel: viewModel)
            }
            .sheet(isPresented: $showMeetingPicker) {
                if let recipe = selectedRecipe {
                    MeetingPickerForRecipe(
                        recipe: recipe,
                        meetings: meetingService.meetings.filter { $0.status == .complete }
                    )
                }
            }
        }
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(MMColors.textPrimary)
            Text("\(count)")
                .font(.caption)
                .foregroundColor(MMColors.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(MMColors.border.opacity(0.5))
                .clipShape(Capsule())
            Spacer()
        }
    }
}

// MARK: - Recipe Card

struct RecipeCard: View {
    let recipe: MeetingRecipe

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: recipe.icon)
                .font(.title2)
                .foregroundColor(MMColors.primary)
                .frame(width: 40, height: 40)
                .background(MMColors.primaryLight)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(recipe.name)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(MMColors.textPrimary)
                .lineLimit(2)

            Text(recipe.prompt)
                .font(.caption)
                .foregroundColor(MMColors.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(MMColors.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(MMColors.border, lineWidth: 1)
        )
    }
}

// MARK: - Meeting Picker for Recipe

struct MeetingPickerForRecipe: View {
    let recipe: MeetingRecipe
    let meetings: [Meeting]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMeeting: Meeting?
    @State private var showResult = false

    var body: some View {
        NavigationStack {
            List {
                if meetings.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(MMColors.textTertiary)
                        Text("No completed meetings")
                            .font(.subheadline)
                            .foregroundColor(MMColors.textSecondary)
                        Text("Record and process a meeting first.")
                            .font(.caption)
                            .foregroundColor(MMColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                } else {
                    Section("Select a meeting to apply \"\(recipe.name)\"") {
                        ForEach(meetings) { meeting in
                            Button {
                                selectedMeeting = meeting
                                showResult = true
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(meeting.title)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(MMColors.textPrimary)
                                        Text(meeting.date, style: .date)
                                            .font(.caption)
                                            .foregroundColor(MMColors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(MMColors.textTertiary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Apply Recipe")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: {
                    #if os(iOS)
                    return .navigationBarLeading
                    #else
                    return .automatic
                    #endif
                }()) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showResult) {
                if let meeting = selectedMeeting {
                    RecipeResultView(
                        recipe: recipe,
                        meeting: meeting
                    )
                }
            }
        }
    }
}

// MARK: - Create Recipe View

struct CreateRecipeView: View {
    @ObservedObject var viewModel: RecipesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var icon = "sparkles"
    @State private var prompt = ""

    private let iconOptions = [
        "sparkles", "lightbulb", "chart.bar", "person.2",
        "doc.text", "checkmark.circle", "flag", "star",
        "bolt", "magnifyingglass", "pencil", "bubble.left.and.bubble.right"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe Name") {
                    TextField("e.g., Summarize for CEO", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(iconOptions, id: \.self) { iconName in
                            Image(systemName: iconName)
                                .font(.title3)
                                .foregroundColor(icon == iconName ? .white : MMColors.primary)
                                .frame(width: 40, height: 40)
                                .background(icon == iconName ? MMColors.primary : MMColors.primaryLight)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture { icon = iconName }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Prompt") {
                    TextEditor(text: $prompt)
                        .frame(minHeight: 120)
                        .font(.subheadline)
                }

                Section {
                    Text("The prompt will be sent as a system instruction to the AI along with the meeting transcript.")
                        .font(.caption)
                        .foregroundColor(MMColors.textTertiary)
                }
            }
            .navigationTitle("Create Recipe")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: {
                    #if os(iOS)
                    return .navigationBarLeading
                    #else
                    return .automatic
                    #endif
                }()) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: {
                    #if os(iOS)
                    return .navigationBarTrailing
                    #else
                    return .automatic
                    #endif
                }()) {
                    Button("Save") {
                        let recipe = MeetingRecipe(
                            name: name,
                            icon: icon,
                            prompt: prompt,
                            isBuiltIn: false
                        )
                        viewModel.addRecipe(recipe)
                        dismiss()
                    }
                    .disabled(name.isEmpty || prompt.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class RecipesViewModel: ObservableObject {
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
    RecipesView()
        .environmentObject(MeetingService.shared)
}
