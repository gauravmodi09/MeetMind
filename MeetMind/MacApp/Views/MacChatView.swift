#if os(macOS)
import SwiftUI

struct MacChatView: View {
    @EnvironmentObject var meetingService: MeetingService
    @EnvironmentObject var todoService: TodoService
    @StateObject private var viewModel = MeetingChatViewModel()
    @State private var showRecipePicker = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            chatHeader
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 16)

            Divider()

            // Messages or welcome
            if viewModel.messages.isEmpty {
                welcomeView
            } else {
                messagesView
            }

            Divider()

            // Recipe picker overlay (shown above input bar)
            if showRecipePicker {
                recipePickerOverlay
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Input
            inputBar
                .padding(16)
        }
        .background(MMColors.backgroundElevated)
        .onChange(of: viewModel.inputText) { _, newValue in
            withAnimation(.easeInOut(duration: 0.2)) {
                showRecipePicker = newValue.hasPrefix("/")
            }
        }
        .onAppear {
            viewModel.meetingService = meetingService
            viewModel.todoService = todoService
        }
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("AI Chat")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(MMColors.textPrimary)
                Text("Ask questions across all your meetings")
                    .font(.system(size: 12))
                    .foregroundColor(MMColors.textTertiary)
            }
            Spacer()
            if !viewModel.messages.isEmpty {
                Button {
                    viewModel.messages.removeAll()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                        Text("Clear")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(MMColors.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(MMColors.background)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Welcome

    private var welcomeView: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 36))
                        .foregroundColor(MMColors.primary.opacity(0.6))
                    Text("Ask your meetings anything")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(MMColors.textPrimary)
                    Text("Search across all your meetings, action items, and tasks using natural language")
                        .font(.system(size: 13))
                        .foregroundColor(MMColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)
                }
                .padding(.top, 40)

                // Quick suggestions
                VStack(alignment: .leading, spacing: 10) {
                    Text("TRY ASKING")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(MMColors.textTertiary)
                        .tracking(0.8)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        suggestionChip("What action items are on me?", icon: "checkmark.circle")
                        suggestionChip("Summarize today's meetings", icon: "doc.text")
                        suggestionChip("What decisions were made this week?", icon: "arrow.right.circle")
                        suggestionChip("How many meetings did I have?", icon: "chart.bar")
                        suggestionChip("Tasks related to Databricks", icon: "tag")
                        suggestionChip("What's my busiest client?", icon: "person.2")
                        suggestionChip("Show overdue items", icon: "exclamationmark.circle")
                        suggestionChip("What did the customer ask for?", icon: "questionmark.bubble")
                    }
                }
                .frame(maxWidth: 520)

                // Recipes
                VStack(alignment: .leading, spacing: 10) {
                    Text("MEETING RECIPES")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(MMColors.textTertiary)
                        .tracking(0.8)

                    let allRecipes = MeetingRecipe.builtIn + loadCustomRecipes()
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(allRecipes) { recipe in
                            recipeCard(recipe)
                        }
                    }
                }
                .frame(maxWidth: 560)
            }
            .padding(28)
        }
    }

    private func suggestionChip(_ text: String, icon: String) -> some View {
        Button {
            viewModel.inputText = text
            sendMessage()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(MMColors.primary)
                Text(text)
                    .font(.system(size: 12))
                    .foregroundColor(MMColors.textSecondary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(MMColors.background)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(MMColors.border))
            )
        }
        .buttonStyle(.plain)
    }

    private func recipeCard(_ recipe: MeetingRecipe) -> some View {
        Button {
            viewModel.inputText = "/\(recipe.name)"
            showRecipePicker = false
            sendMessage()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: recipe.icon)
                    .font(.system(size: 16))
                    .foregroundColor(MMColors.primary)
                Text(recipe.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MMColors.textPrimary)
                Text(String(recipe.prompt.prefix(60)))
                    .font(.system(size: 10))
                    .foregroundColor(MMColors.textTertiary)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(MMColors.background)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(MMColors.border))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Messages

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    if viewModel.isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Searching meetings...")
                                .font(.system(size: 12))
                                .foregroundColor(MMColors.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .id("loading")
                    }
                }
                .padding(24)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation {
                    if let last = viewModel.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isLoading) { _, loading in
                if loading {
                    withAnimation {
                        proxy.scrollTo("loading", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Recipe Picker Overlay

    private var recipePickerOverlay: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RECIPES")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(MMColors.textSecondary)
                .tracking(0.8)
                .padding(.horizontal, 12)

            let query = String(viewModel.inputText.dropFirst()).lowercased()
            let allRecipes = MeetingRecipe.builtIn + loadCustomRecipes()
            let filtered = query.isEmpty ? allRecipes : allRecipes.filter { $0.name.lowercased().contains(query) }

            if filtered.isEmpty {
                Text("No matching recipes")
                    .font(.system(size: 12))
                    .foregroundColor(MMColors.textTertiary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
            } else {
                ForEach(filtered) { recipe in
                    Button {
                        viewModel.inputText = "/\(recipe.name)"
                        showRecipePicker = false
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: recipe.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(MMColors.primary)
                                .frame(width: 28, height: 28)
                                .background(MMColors.primaryLight)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Text(recipe.name)
                                .font(.system(size: 13))
                                .foregroundColor(MMColors.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 10)
        .background(MMColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.12), radius: 8, y: -4)
        .padding(.horizontal, 16)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 8) {
            // Model selector pill
            HStack {
                Menu {
                    Section("Groq (Fast)") {
                        ForEach(ChatModel.allCases.filter { $0.provider == .groq }) { model in
                            Button {
                                GroqService.shared.selectedChatModel = model
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(model.label)
                                        Text(model.subtitle)
                                    }
                                    if GroqService.shared.selectedChatModel == model {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                    Section("Gemini (Quality)") {
                        ForEach(ChatModel.allCases.filter { $0.provider == .gemini }) { model in
                            Button {
                                GroqService.shared.selectedChatModel = model
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(model.label)
                                        Text(model.subtitle)
                                    }
                                    if GroqService.shared.selectedChatModel == model {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: GroqService.shared.selectedChatModel.provider == .gemini ? "sparkles" : "cpu")
                            .font(.system(size: 10, weight: .medium))
                        Text(GroqService.shared.selectedChatModel.label)
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .medium))
                    }
                    .foregroundColor(MMColors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(MMColors.primaryLight)
                    .clipShape(Capsule())
                }
                .menuStyle(.borderlessButton)

                Spacer()
            }

            // Text field row
            HStack(spacing: 10) {
                // Recipe menu button
                Menu {
                    let allRecipes = MeetingRecipe.builtIn + loadCustomRecipes()
                    ForEach(allRecipes) { recipe in
                        Button {
                            viewModel.inputText = "/\(recipe.name)"
                            sendMessage()
                        } label: {
                            Label(recipe.name, systemImage: recipe.icon)
                        }
                    }
                } label: {
                    Image(systemName: "sparkle")
                        .font(.system(size: 14))
                        .foregroundColor(MMColors.primary)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(MMColors.primary.opacity(0.08))
                        )
                }
                .menuStyle(.borderlessButton)
                .frame(width: 32)

                // Text field
                TextField("Ask about your meetings...", text: $viewModel.inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isInputFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(MMColors.background)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(MMColors.border))
                    )
                    .onSubmit { sendMessage() }

                // Send button
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(
                            viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading
                            ? MMColors.textTertiary
                            : MMColors.primary
                        )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
        }
    }

    // MARK: - Helpers

    private func loadCustomRecipes() -> [MeetingRecipe] {
        guard let data = UserDefaults.standard.data(forKey: "customMeetingRecipes"),
              let recipes = try? JSONDecoder().decode([MeetingRecipe].self, from: data) else {
            return []
        }
        return recipes
    }

    private func sendMessage() {
        let text = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Handle recipe "/" commands
        if text.hasPrefix("/") {
            let recipeName = String(text.dropFirst()).trimmingCharacters(in: .whitespaces)
            let allRecipes = MeetingRecipe.builtIn + loadCustomRecipes()
            if let recipe = allRecipes.first(where: { $0.name.lowercased() == recipeName.lowercased() }) {
                viewModel.inputText = ""
                showRecipePicker = false
                isInputFocused = false
                Task {
                    await viewModel.executeRecipe(recipe)
                }
                return
            }
        }

        viewModel.inputText = ""
        showRecipePicker = false
        isInputFocused = false
        Task {
            await viewModel.sendQuery(text)
        }
    }
}
#endif
