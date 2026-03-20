import Foundation

@MainActor
class TeamsIntegrationService: ObservableObject {
    static let shared = TeamsIntegrationService()

    @Published var isSending = false
    @Published var lastError: String?

    private init() {}

    /// Send meeting notes to a Teams channel via Incoming Webhook
    func sendToTeams(title: String, summary: String, actionItems: [String], webhookURL: String) async -> Bool {
        guard let url = URL(string: webhookURL) else {
            lastError = "Invalid webhook URL"
            return false
        }

        isSending = true
        lastError = nil

        // Build Teams Adaptive Card payload
        var sections: [[String: Any]] = []

        // Summary section
        sections.append([
            "activityTitle": title,
            "activitySubtitle": "Meeting Notes from MeetMind",
            "facts": [["name": "Summary", "value": String(summary.prefix(500))]],
            "markdown": true
        ])

        // Action items
        if !actionItems.isEmpty {
            let itemsText = actionItems.map { "- \($0)" }.joined(separator: "\n")
            sections.append([
                "activityTitle": "Action Items",
                "text": itemsText,
                "markdown": true
            ])
        }

        let payload: [String: Any] = [
            "@type": "MessageCard",
            "@context": "http://schema.org/extensions",
            "themeColor": "6C5CE7",
            "summary": title,
            "sections": sections
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        request.timeoutInterval = 15

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            isSending = false
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                return true
            }
            lastError = "Teams returned an error"
            return false
        } catch {
            isSending = false
            lastError = error.localizedDescription
            return false
        }
    }
}
