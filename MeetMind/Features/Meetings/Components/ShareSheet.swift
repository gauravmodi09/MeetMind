import SwiftUI
import UIKit

// MARK: - ShareSheet (UIActivityViewController wrapper)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?

    init(items: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil) {
        self.items = items
        self.excludedActivityTypes = excludedActivityTypes
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Text File Activity Item

/// Provides a .txt file export alongside the plain text for share sheet.
class MeetingBriefTextFileItem: NSObject, UIActivityItemSource {
    let briefText: String
    let meetingTitle: String

    init(briefText: String, meetingTitle: String) {
        self.briefText = briefText
        self.meetingTitle = meetingTitle
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return briefText
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        // For AirDrop / Files, provide a .txt file URL
        if activityType == .airDrop || activityType == .init(rawValue: "com.apple.DocumentManagerUICore.SaveToFiles") {
            return createTempTextFile()
        }
        return briefText
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        return "Meeting Brief: \(meetingTitle)"
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        return "public.plain-text"
    }

    private func createTempTextFile() -> URL? {
        let sanitized = meetingTitle
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let filename = "\(sanitized) Brief.txt"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? briefText.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }
}
