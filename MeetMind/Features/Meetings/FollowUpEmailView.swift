import SwiftUI

struct FollowUpEmailView: View {
    let meeting: Meeting

    @Environment(\.dismiss) private var dismiss
    @State private var emailText: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var copiedEmail = false
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                MMColors.background.ignoresSafeArea()

                if isLoading {
                    loadingState
                } else if let error = errorMessage {
                    errorState(error)
                } else {
                    emailEditor
                }
            }
            .navigationTitle("Follow-up Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(MMColors.primary)
                }

                if !isLoading && errorMessage == nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                copyEmail()
                            } label: {
                                Label("Copy Email", systemImage: "doc.on.doc")
                            }

                            Button {
                                showShareSheet = true
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(MMColors.primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [emailText])
                    .presentationDetents([.medium, .large])
            }
            .task {
                await generateEmail()
            }
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(MMColors.primary)

            VStack(spacing: 6) {
                Text("Writing your follow-up email...")
                    .font(MMTypography.headline)
                    .foregroundColor(MMColors.textPrimary)

                Text("AI is crafting a professional email based on the meeting brief")
                    .font(MMTypography.footnote)
                    .foregroundColor(MMColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error State

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(MMColors.warning)

            Text("Could not generate email")
                .font(MMTypography.headline)
                .foregroundColor(MMColors.textPrimary)

            Text(message)
                .font(MMTypography.footnote)
                .foregroundColor(MMColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)

            MMButton("Try Again", icon: "arrow.clockwise", style: .secondary) {
                isLoading = true
                errorMessage = nil
                Task {
                    await generateEmail()
                }
            }
            .frame(width: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Email Editor

    private var emailEditor: some View {
        VStack(spacing: 0) {
            // Email preview/editor
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Subject line hint
                    HStack(spacing: 8) {
                        Text("Subject:")
                            .font(MMTypography.footnoteMedium)
                            .foregroundColor(MMColors.textSecondary)

                        Text("Follow-up: \(meeting.title)")
                            .font(MMTypography.footnote)
                            .foregroundColor(MMColors.textPrimary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    Divider()
                        .padding(.horizontal, 16)

                    TextEditor(text: $emailText)
                        .font(.system(.body))
                        .foregroundColor(MMColors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 400)
                        .padding(.horizontal, 12)
                }
            }
            .background(MMColors.cardBg)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Bottom action bar
            HStack(spacing: 12) {
                MMButton(copiedEmail ? "Copied!" : "Copy Email", icon: copiedEmail ? "checkmark" : "doc.on.doc", style: .secondary) {
                    copyEmail()
                }

                MMButton("Share", icon: "square.and.arrow.up") {
                    showShareSheet = true
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(MMColors.background)
        }
    }

    // MARK: - Actions

    private func generateEmail() async {
        do {
            let brief = MeetingBriefFormatter.format(meeting: meeting)
            let email = try await GroqService.shared.generateFollowUpEmail(
                brief: brief,
                meetingTitle: meeting.title
            )
            emailText = email
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func copyEmail() {
        UIPasteboard.general.string = emailText
        copiedEmail = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedEmail = false
        }
    }
}

// MARK: - Preview

#Preview {
    FollowUpEmailView(
        meeting: Meeting(
            title: "Weekly Sync with Acme Corp",
            date: Date(),
            duration: 1800,
            clientName: "Acme Corp",
            status: .complete,
            briefSummary: "Discussed Q3 revenue targets and agreed to accelerate the product roadmap.",
            briefDecisions: ["Move to bi-weekly sprint cycles"],
            briefActionItems: [
                ActionItem(text: "Send updated proposal", owner: "Me", isMine: true)
            ],
            briefKeyTopics: ["Q3 Targets", "Roadmap"]
        )
    )
}
