#if os(iOS)
import UIKit

// MARK: - MeetingPDFRenderer
// Renders a Meeting into a polished, branded PDF (Genspark-style): a header
// band, AI summary, decisions, action items, key topics, key quotes, and an
// optional full-transcript appendix. Pure `Meeting -> Data`.
//
// UIGraphicsPDFRenderer hands us a blank canvas per page with no automatic
// reflow, so `PDFLayoutContext` threads a single cursor through every draw
// call and breaks to a new page (stamping a footer first) whenever the next
// block would overflow the bottom margin.

enum MeetingPDFRenderer {

    // A4 at 72 dpi.
    private static let pageSize = CGSize(width: 595.2, height: 841.8)
    private static let margin: CGFloat = 48

    // Brand palette (matches MMColors primary #6C5CE7).
    private static let accent = UIColor(red: 0x6C/255, green: 0x5C/255, blue: 0xE7/255, alpha: 1)
    private static let ink = UIColor(white: 0.10, alpha: 1)
    private static let inkSecondary = UIColor(white: 0.40, alpha: 1)
    private static let hairline = UIColor(white: 0.85, alpha: 1)

    /// Render a meeting to PDF data. `includeTranscript` appends the full
    /// speaker-labeled transcript on a new page.
    static func render(meeting: Meeting, includeTranscript: Bool) -> Data {
        let pageRect = CGRect(origin: .zero, size: pageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { rendererCtx in
            let layout = PDFLayoutContext(
                rendererCtx: rendererCtx,
                pageRect: pageRect,
                margin: margin,
                accent: accent,
                inkSecondary: inkSecondary
            )
            layout.beginPage()

            drawHeaderBand(meeting: meeting, layout: layout)
            layout.advance(by: 18)

            // Summary (markdown -> attributed)
            if let summary = meeting.briefSummary?.trimmingCharacters(in: .whitespacesAndNewlines),
               !summary.isEmpty {
                layout.drawSectionTitle("Summary")
                layout.draw(MarkdownPDF.attributed(summary, baseColor: ink), spacingAfter: 16)
            }

            // Decisions
            if !meeting.briefDecisions.isEmpty {
                layout.drawSectionTitle("Decisions")
                for (idx, decision) in meeting.briefDecisions.enumerated() {
                    layout.drawNumbered(idx + 1, text: decision, color: ink)
                }
                layout.advance(by: 12)
            }

            // Action items
            if !meeting.briefActionItems.isEmpty {
                layout.drawSectionTitle("Action items")
                for item in meeting.briefActionItems {
                    layout.drawCheckbox(
                        checked: item.isCompleted,
                        text: item.text,
                        meta: actionMeta(item),
                        textColor: ink,
                        metaColor: inkSecondary
                    )
                }
                layout.advance(by: 12)
            }

            // Key topics (chips)
            if !meeting.briefKeyTopics.isEmpty {
                layout.drawSectionTitle("Key topics")
                layout.drawChips(meeting.briefKeyTopics)
                layout.advance(by: 12)
            }

            // Key quotes (blockquote)
            if !meeting.briefKeyQuotes.isEmpty {
                layout.drawSectionTitle("Key quotes")
                for quote in meeting.briefKeyQuotes {
                    layout.drawBlockquote(quote, color: inkSecondary)
                }
                layout.advance(by: 12)
            }

            // Transcript appendix
            if includeTranscript,
               let transcript = meeting.rawTranscript?.trimmingCharacters(in: .whitespacesAndNewlines),
               !transcript.isEmpty {
                layout.startNewPage()
                layout.drawSectionTitle("Transcript")
                for paragraph in transcript.components(separatedBy: "\n") {
                    let line = paragraph.trimmingCharacters(in: .whitespaces)
                    guard !line.isEmpty else { continue }
                    layout.drawParagraph(line, color: inkSecondary, font: .systemFont(ofSize: 10))
                }
            }

            layout.finishCurrentPage()
        }
    }

    // MARK: - Header band

    private static func drawHeaderBand(meeting: Meeting, layout: PDFLayoutContext) {
        let bandHeight: CGFloat = 92
        let rect = CGRect(x: 0, y: 0, width: pageSize.width, height: bandHeight)
        accent.setFill()
        UIBezierPath(rect: rect).fill()

        let leftX = margin
        var y: CGFloat = 18

        // Wordmark
        let wordmark = NSAttributedString(string: "MeetMind", attributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.85),
            .kern: 1.5
        ])
        wordmark.draw(at: CGPoint(x: leftX, y: y))
        y += 20

        // Title
        let title = NSAttributedString(string: meeting.title, attributes: [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor.white
        ])
        let titleRect = title.boundingRect(
            with: CGSize(width: pageSize.width - 2 * margin, height: 40),
            options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil
        )
        title.draw(in: CGRect(x: leftX, y: y, width: pageSize.width - 2 * margin, height: titleRect.height))
        y += titleRect.height + 4

        // Meta line
        let meta = NSAttributedString(string: headerMeta(meeting), attributes: [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.9)
        ])
        meta.draw(at: CGPoint(x: leftX, y: y))

        layout.setCursor(below: bandHeight + 24)
    }

    private static func headerMeta(_ meeting: Meeting) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        var parts = [df.string(from: meeting.date), durationString(meeting.duration)]
        if let client = meeting.clientName, !client.isEmpty { parts.append(client) }
        parts.append(meeting.template.rawValue)
        return parts.joined(separator: "  ·  ")
    }

    private static func durationString(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 { return "\(minutes) min" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    private static func actionMeta(_ item: ActionItem) -> String {
        var bits: [String] = []
        if !item.owner.isEmpty { bits.append(item.owner) }
        if item.isMine { bits.append("you") }
        if let due = item.dueDate {
            let df = DateFormatter()
            df.dateFormat = "MMM d"
            bits.append("due \(df.string(from: due))")
        }
        return bits.isEmpty ? "" : "— " + bits.joined(separator: " · ")
    }
}
#endif
