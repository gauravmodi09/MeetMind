#if os(iOS)
import XCTest
import PDFKit
@testable import MeetMind

final class MeetingPDFRendererTests: XCTestCase {

    private func fixture(transcriptWords: Int = 400) -> Meeting {
        let transcript = Array(repeating: "Speaker discussed the roadmap and next steps.", count: transcriptWords / 7)
            .joined(separator: " ")
        return Meeting(
            title: "Q3 Planning Sync",
            date: Date(timeIntervalSince1970: 1_700_000_000),
            duration: 3_660, // 1h 1m
            clientName: "Acme Corp",
            status: .complete,
            template: .salesCall,
            briefSummary: "## Overview\nThe team aligned on **Q3 priorities**.\n\n- Ship the PDF export\n- Finish watch recording",
            briefDecisions: ["Adopt the new pricing tier", "Delay the EU launch to Q4"],
            briefActionItems: [
                ActionItem(text: "Send the revised proposal", owner: "Gaurav", dueDate: Date(), isMine: true, isCompleted: false),
                ActionItem(text: "Schedule the follow-up demo", owner: "Priya", isMine: false, isCompleted: true)
            ],
            briefKeyTopics: ["pricing", "roadmap", "hiring", "compliance"],
            briefKeyQuotes: ["This is exactly what we needed."],
            rawTranscript: transcript
        )
    }

    func testRendersNonEmptyValidPDF() {
        let data = MeetingPDFRenderer.render(meeting: fixture(), includeTranscript: true)
        XCTAssertFalse(data.isEmpty, "PDF data should not be empty")
        let doc = PDFDocument(data: data)
        XCTAssertNotNil(doc, "Rendered data should be a valid PDF")
        XCTAssertGreaterThanOrEqual(doc!.pageCount, 1)
    }

    func testContainsTitleAndActionItemText() {
        let data = MeetingPDFRenderer.render(meeting: fixture(), includeTranscript: false)
        let doc = PDFDocument(data: data)!
        let text = (0..<doc.pageCount).compactMap { doc.page(at: $0)?.string }.joined(separator: "\n")
        XCTAssertTrue(text.contains("Q3 Planning Sync"), "PDF should contain the meeting title")
        XCTAssertTrue(text.contains("Send the revised proposal"), "PDF should contain an action item")
        XCTAssertTrue(text.contains("Acme Corp"), "PDF should contain the client name")
    }

    func testTranscriptToggleChangesPageCount() {
        let withTranscript = MeetingPDFRenderer.render(meeting: fixture(transcriptWords: 1500), includeTranscript: true)
        let without = MeetingPDFRenderer.render(meeting: fixture(transcriptWords: 1500), includeTranscript: false)
        let withPages = PDFDocument(data: withTranscript)!.pageCount
        let withoutPages = PDFDocument(data: without)!.pageCount
        XCTAssertGreaterThan(withPages, withoutPages, "Including a long transcript should add pages")
    }

    func testEmptyBriefStillRenders() {
        let bare = Meeting(title: "Untitled", status: .complete)
        let data = MeetingPDFRenderer.render(meeting: bare, includeTranscript: true)
        XCTAssertNotNil(PDFDocument(data: data))
        XCTAssertGreaterThanOrEqual(PDFDocument(data: data)!.pageCount, 1)
    }
}
#endif
