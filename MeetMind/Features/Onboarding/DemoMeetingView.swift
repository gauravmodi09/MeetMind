import SwiftUI

struct DemoMeetingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasOnboarded = false

    var body: some View {
        ZStack {
            MMColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Here's what MeetMind produces")
                            .font(MMTypography.title2)
                            .foregroundColor(MMColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        Text("From a single recording, you get a complete brief.")
                            .font(MMTypography.subheadline)
                            .foregroundColor(MMColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 16)

                    // Meeting brief card
                    VStack(alignment: .leading, spacing: 20) {
                        // Title + meta
                        VStack(alignment: .leading, spacing: 6) {
                            Text(DemoData.title)
                                .font(MMTypography.title3)
                                .foregroundColor(MMColors.textPrimary)

                            Text("Mar 18, 2026 \u{00B7} 24 min")
                                .font(MMTypography.caption1)
                                .foregroundColor(MMColors.textTertiary)
                        }

                        Divider()

                        // Summary
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("Summary")
                            Text(DemoData.summary)
                                .font(MMTypography.body)
                                .foregroundColor(MMColors.textPrimary)
                        }

                        // Decisions
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("Decisions")
                            ForEach(DemoData.decisions, id: \.self) { decision in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(MMColors.success)
                                        .padding(.top, 2)
                                    Text(decision)
                                        .font(MMTypography.subheadline)
                                        .foregroundColor(MMColors.textPrimary)
                                }
                            }
                        }

                        // Action Items
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("Action Items")
                            ForEach(DemoData.actionItems, id: \.self) { item in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "circle")
                                        .font(.system(size: 14))
                                        .foregroundColor(MMColors.primary)
                                        .padding(.top, 2)
                                    Text(item)
                                        .font(MMTypography.subheadline)
                                        .foregroundColor(MMColors.textPrimary)
                                }
                            }
                        }

                        // Key Topics
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("Key Topics")
                            FlowLayout(spacing: 8) {
                                ForEach(DemoData.topics, id: \.self) { topic in
                                    Text(topic)
                                        .font(MMTypography.caption1)
                                        .foregroundColor(MMColors.primary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            Capsule()
                                                .fill(MMColors.primaryLight)
                                        )
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(MMColors.cardBg)
                            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
                    )

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
            }

            // CTA button pinned to bottom
            VStack {
                Spacer()
                MMButton("Start Recording Your First Meeting", icon: "mic.fill") {
                    hasOnboarded = true
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(MMTypography.footnoteMedium)
            .foregroundColor(MMColors.textTertiary)
            .textCase(.uppercase)
    }
}

// MARK: - Flow Layout


// MARK: - Demo Data

private enum DemoData {
    static let title = "Strategic Planning for Meyer Account"
    static let summary = "Mitchell (Databricks) and Gaurav (Celebal) discussed the Meyer account progress. Maju wants to hire 6 more Celebal engineers due to strong technical leadership. The Metrics View POC is progressing well but blocked on table access for 4-5 remaining tables. They agreed on a hybrid approach keeping presentation-layer logic in Power BI while migrating core transformations to Databricks Metric Views. A readout is planned for the week of March 26th."
    static let decisions = [
        "Adopt hybrid POC approach — keep UI filters in Power BI, core metrics in Databricks",
        "Use self-service workspace for testing to bypass production deployment bottleneck",
        "Target final POC readout for week of March 26th",
        "Gaurav to create summary presentation with key talking points for David"
    ]
    static let actionItems = [
        "Gaurav: Create summary presentation for David by tomorrow",
        "Gaurav: Talk to Pankaj about self-service workspace access",
        "Mitchell: Send self-service workspace role name to Gaurav",
        "Gaurav: Follow up proactively on remaining table access"
    ]
    static let topics = ["Meyer Account", "Metrics View POC", "Databricks Migration", "Azure Analysis Services", "Teradata Profiling"]
}
