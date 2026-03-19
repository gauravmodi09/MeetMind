import SwiftUI

struct RecipeResultView: View {
    let recipe: MeetingRecipe
    let meeting: Meeting
    @Environment(\.dismiss) private var dismiss
    @State private var result = ""
    @State private var isLoading = true
    @State private var error: String?
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                MMColors.background.ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if let error {
                    errorView(error)
                } else {
                    resultContent
                }
            }
            .navigationTitle(recipe.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                if !isLoading && error == nil {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            copyResult()
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        Button {
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [result])
            }
        }
        .task {
            await executeRecipe()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Applying \"\(recipe.name)\"...")
                .font(.subheadline)
                .foregroundColor(MMColors.textSecondary)
            Text(meeting.title)
                .font(.caption)
                .foregroundColor(MMColors.textTertiary)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(MMColors.warning)
            Text("Recipe Failed")
                .font(.headline)
                .foregroundColor(MMColors.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(MMColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try Again") {
                isLoading = true
                error = nil
                Task { await executeRecipe() }
            }
            .buttonStyle(.borderedProminent)
            .tint(MMColors.primary)
        }
    }

    private var resultContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Meeting context
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                        .font(.caption)
                        .foregroundColor(MMColors.primary)
                    Text(meeting.title)
                        .font(.caption.weight(.medium))
                        .foregroundColor(MMColors.textSecondary)
                    Spacer()
                    Text(meeting.date, style: .date)
                        .font(.caption)
                        .foregroundColor(MMColors.textTertiary)
                }
                .padding(12)
                .background(MMColors.primaryLight.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Result
                Text(result)
                    .font(.subheadline)
                    .foregroundColor(MMColors.textPrimary)
                    .textSelection(.enabled)
                    .lineSpacing(4)
            }
            .padding(16)
        }
    }

    // MARK: - Actions

    private func executeRecipe() async {
        guard let transcript = meeting.rawTranscript, !transcript.isEmpty else {
            error = "This meeting has no transcript available."
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
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    private func copyResult() {
        #if canImport(UIKit)
        UIPasteboard.general.string = result
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result, forType: .string)
        #endif
    }
}

// MARK: - Preview

#Preview {
    RecipeResultView(
        recipe: MeetingRecipe.builtIn[0],
        meeting: Meeting(title: "Sample Meeting", status: .complete, rawTranscript: "Hello world")
    )
}
