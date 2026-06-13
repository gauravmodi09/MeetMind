#if os(iOS)
import UIKit

// MARK: - PDFLayoutContext
// Owns the page cursor and pagination for MeetingPDFRenderer. Every draw
// helper measures its block, asks `ensureSpace` to page-break if needed, draws
// at the current cursor, then advances. Each page gets a numbered footer,
// stamped just before the page is left (or at the very end).

final class PDFLayoutContext {
    private let rendererCtx: UIGraphicsPDFRendererContext
    private let pageRect: CGRect
    private let margin: CGFloat
    private let accent: UIColor
    private let inkSecondary: UIColor

    private let footerHeight: CGFloat = 28
    private(set) var cursorY: CGFloat = 0
    private var pageNumber = 0
    private var pageStarted = false

    private var contentWidth: CGFloat { pageRect.width - 2 * margin }
    private var contentBottom: CGFloat { pageRect.height - margin - footerHeight }

    init(rendererCtx: UIGraphicsPDFRendererContext, pageRect: CGRect, margin: CGFloat,
         accent: UIColor, inkSecondary: UIColor) {
        self.rendererCtx = rendererCtx
        self.pageRect = pageRect
        self.margin = margin
        self.accent = accent
        self.inkSecondary = inkSecondary
    }

    // MARK: - Page lifecycle

    func beginPage() {
        rendererCtx.beginPage()
        pageNumber += 1
        pageStarted = true
        cursorY = margin
    }

    /// Stamp the footer on the current page (does not start a new one).
    func finishCurrentPage() {
        guard pageStarted else { return }
        drawFooter()
    }

    /// Force a page break (footer on current page, fresh page after).
    func startNewPage() {
        finishCurrentPage()
        beginPage()
    }

    /// Reserve `height`; break to a new page if it won't fit.
    func ensureSpace(_ height: CGFloat) {
        if cursorY + height > contentBottom {
            startNewPage()
        }
    }

    func advance(by amount: CGFloat) { cursorY += amount }

    /// Used by the header band, which draws its own background and sets where
    /// body content should begin.
    func setCursor(below y: CGFloat) { cursorY = y }

    // MARK: - Draw helpers

    func drawSectionTitle(_ title: String) {
        let attr = NSAttributedString(string: title.uppercased(), attributes: [
            .font: UIFont.systemFont(ofSize: 11, weight: .heavy),
            .foregroundColor: accent,
            .kern: 1.2
        ])
        let h = measure(attr)
        ensureSpace(h + 10)
        attr.draw(in: CGRect(x: margin, y: cursorY, width: contentWidth, height: h))
        cursorY += h + 4
        // accent rule
        accent.withAlphaComponent(0.25).setStroke()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: cursorY))
        path.addLine(to: CGPoint(x: margin + contentWidth, y: cursorY))
        path.lineWidth = 0.5
        path.stroke()
        cursorY += 8
    }

    func draw(_ attributed: NSAttributedString, spacingAfter: CGFloat) {
        let h = measure(attributed)
        ensureSpace(h)
        attributed.draw(in: CGRect(x: margin, y: cursorY, width: contentWidth, height: h))
        cursorY += h + spacingAfter
    }

    func drawParagraph(_ text: String, color: UIColor, font: UIFont = .systemFont(ofSize: 12)) {
        let attr = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
        draw(attr, spacingAfter: 4)
    }

    func drawNumbered(_ number: Int, text: String, color: UIColor) {
        let bullet = NSAttributedString(string: "\(number).  ", attributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold), .foregroundColor: accent
        ])
        drawHanging(marker: bullet, text: text, color: color)
    }

    func drawCheckbox(checked: Bool, text: String, meta: String, textColor: UIColor, metaColor: UIColor) {
        let glyph = checked ? "\u{2611}  " : "\u{2610}  " // ☑ / ☐
        let marker = NSAttributedString(string: glyph, attributes: [
            .font: UIFont.systemFont(ofSize: 13), .foregroundColor: checked ? accent : metaColor
        ])
        let body = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 12), .foregroundColor: textColor
        ])
        if !meta.isEmpty {
            body.append(NSAttributedString(string: "  \(meta)", attributes: [
                .font: UIFont.systemFont(ofSize: 10, weight: .medium), .foregroundColor: metaColor
            ]))
        }
        drawHanging(marker: marker, attributedText: body)
    }

    func drawBlockquote(_ text: String, color: UIColor) {
        let inset: CGFloat = 12
        let attr = NSAttributedString(string: "\u{201C}\(text)\u{201D}", attributes: [
            .font: UIFont.italicSystemFont(ofSize: 12), .foregroundColor: color
        ])
        let usableWidth = contentWidth - inset
        let h = measure(attr, width: usableWidth)
        ensureSpace(h + 6)
        accent.setFill()
        UIBezierPath(rect: CGRect(x: margin, y: cursorY, width: 3, height: h)).fill()
        attr.draw(in: CGRect(x: margin + inset, y: cursorY, width: usableWidth, height: h))
        cursorY += h + 8
    }

    func drawChips(_ items: [String]) {
        let hPad: CGFloat = 9, vPad: CGFloat = 4, gap: CGFloat = 6, rowH: CGFloat = 22
        let font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        var x = margin
        ensureSpace(rowH)
        var rowTop = cursorY

        for item in items {
            let label = "#\(item)"
            let textW = (label as NSString).size(withAttributes: [.font: font]).width
            let chipW = textW + hPad * 2
            if x + chipW > margin + contentWidth {
                x = margin
                rowTop += rowH + gap
                ensureSpaceAt(&rowTop, height: rowH)
            }
            let chipRect = CGRect(x: x, y: rowTop, width: chipW, height: rowH - vPad)
            accent.withAlphaComponent(0.12).setFill()
            UIBezierPath(roundedRect: chipRect, cornerRadius: (rowH - vPad) / 2).fill()
            NSAttributedString(string: label, attributes: [.font: font, .foregroundColor: accent])
                .draw(at: CGPoint(x: x + hPad, y: rowTop + vPad))
            x += chipW + gap
        }
        cursorY = rowTop + rowH
    }

    // MARK: - Private

    private func drawHanging(marker: NSAttributedString, text: String, color: UIColor) {
        let body = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 12), .foregroundColor: color
        ])
        drawHanging(marker: marker, attributedText: body)
    }

    private func drawHanging(marker: NSAttributedString, attributedText: NSAttributedString) {
        let markerW = ceil(marker.size().width)
        let textWidth = contentWidth - markerW
        let h = measure(attributedText, width: textWidth)
        ensureSpace(h + 4)
        marker.draw(at: CGPoint(x: margin, y: cursorY))
        attributedText.draw(in: CGRect(x: margin + markerW, y: cursorY, width: textWidth, height: h))
        cursorY += h + 5
    }

    private func ensureSpaceAt(_ top: inout CGFloat, height: CGFloat) {
        if top + height > contentBottom {
            startNewPage()
            top = cursorY
        }
    }

    private func measure(_ attr: NSAttributedString, width: CGFloat? = nil) -> CGFloat {
        let w = width ?? contentWidth
        let rect = attr.boundingRect(
            with: CGSize(width: w, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil
        )
        return ceil(rect.height)
    }

    private func drawFooter() {
        let y = pageRect.height - margin
        hairlineRule(atY: y - 8)
        let text = NSAttributedString(string: "Generated by MeetMind  ·  page \(pageNumber)", attributes: [
            .font: UIFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: inkSecondary
        ])
        text.draw(at: CGPoint(x: margin, y: y))
    }

    private func hairlineRule(atY y: CGFloat) {
        UIColor(white: 0.85, alpha: 1).setStroke()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
        path.lineWidth = 0.5
        path.stroke()
    }
}

// MARK: - MarkdownPDF
// Minimal markdown -> NSAttributedString for the AI summary. Handles ATX
// headers (#, ##, ###), unordered bullets (-, *), and inline **bold**.
// Deliberately small and dependency-free; the brief summaries only use this
// subset.

enum MarkdownPDF {
    static func attributed(_ markdown: String, baseColor: UIColor) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = markdown.components(separatedBy: "\n")
        let para = NSMutableParagraphStyle()
        para.paragraphSpacing = 4
        para.lineSpacing = 2

        for (idx, raw) in lines.enumerated() {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                result.append(NSAttributedString(string: "\n"))
                continue
            }

            let (text, font, color, indent): (String, UIFont, UIColor, Bool)
            if line.hasPrefix("### ") {
                text = String(line.dropFirst(4)); font = .systemFont(ofSize: 13, weight: .semibold); color = baseColor; indent = false
            } else if line.hasPrefix("## ") {
                text = String(line.dropFirst(3)); font = .systemFont(ofSize: 15, weight: .bold); color = baseColor; indent = false
            } else if line.hasPrefix("# ") {
                text = String(line.dropFirst(2)); font = .systemFont(ofSize: 17, weight: .bold); color = baseColor; indent = false
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                text = "•  " + String(line.dropFirst(2)); font = .systemFont(ofSize: 12); color = baseColor; indent = true
            } else {
                text = line; font = .systemFont(ofSize: 12); color = baseColor; indent = false
            }

            let lineAttr = inlineBold(text, font: font, color: color)
            let mutableLine = NSMutableAttributedString(attributedString: lineAttr)
            let lineStyle = NSMutableParagraphStyle()
            lineStyle.paragraphSpacing = 4
            lineStyle.lineSpacing = 2
            if indent { lineStyle.headIndent = 14; lineStyle.firstLineHeadIndent = 0 }
            mutableLine.addAttribute(.paragraphStyle, value: lineStyle, range: NSRange(location: 0, length: mutableLine.length))
            result.append(mutableLine)
            if idx < lines.count - 1 { result.append(NSAttributedString(string: "\n")) }
        }
        return result
    }

    /// Parse `**bold**` spans into bold runs, leaving other text in `font`.
    private static func inlineBold(_ text: String, font: UIFont, color: UIColor) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let boldFont = UIFont.systemFont(ofSize: font.pointSize, weight: .bold)
        var rest = Substring(text)
        while let open = rest.range(of: "**") {
            let before = rest[rest.startIndex..<open.lowerBound]
            if !before.isEmpty {
                result.append(NSAttributedString(string: String(before), attributes: [.font: font, .foregroundColor: color]))
            }
            let afterOpen = rest[open.upperBound...]
            if let close = afterOpen.range(of: "**") {
                let boldText = afterOpen[afterOpen.startIndex..<close.lowerBound]
                result.append(NSAttributedString(string: String(boldText), attributes: [.font: boldFont, .foregroundColor: color]))
                rest = afterOpen[close.upperBound...]
            } else {
                // Unbalanced — treat the rest as plain.
                result.append(NSAttributedString(string: String(afterOpen), attributes: [.font: font, .foregroundColor: color]))
                rest = Substring("")
                break
            }
        }
        if !rest.isEmpty {
            result.append(NSAttributedString(string: String(rest), attributes: [.font: font, .foregroundColor: color]))
        }
        return result
    }
}
#endif
