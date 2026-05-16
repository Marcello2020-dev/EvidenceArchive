import Foundation
import UIKit

struct ExportService {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func exportFolder(for caseFile: CaseFile) throws -> URL {
        let caseRoot = try StorageLayout.caseRootURL(caseID: caseFile.id, fileManager: fileManager)
        let evidenceSourceFolder = caseRoot.appendingPathComponent("evidence", isDirectory: true)

        let exportContainer = try StorageLayout.exportsFolderURL(caseID: caseFile.id, fileManager: fileManager)

        let exportName = "Evidence Archive - \(SafeFilename.sanitizeStem(caseFile.title))"
        let exportRoot = uniqueFolderURL(baseFolder: exportContainer, preferredName: exportName)
        let evidenceTarget = exportRoot.appendingPathComponent("Evidence", isDirectory: true)

        try fileManager.createDirectory(at: evidenceTarget, withIntermediateDirectories: true)

        let sortedEvidence = caseFile.evidenceList.sorted { lhs, rhs in
            if lhs.eventDate != rhs.eventDate { return lhs.eventDate > rhs.eventDate }
            return lhs.importedAt > rhs.importedAt
        }

        for item in sortedEvidence {
            let src = evidenceSourceFolder.appendingPathComponent(item.storedFilename, isDirectory: false)
            let dst = evidenceTarget.appendingPathComponent(item.storedFilename, isDirectory: false)
            if fileManager.fileExists(atPath: src.path) {
                try fileManager.copyItem(at: src, to: dst)
            }
        }

        let csvURL = exportRoot.appendingPathComponent("00_Index.csv", isDirectory: false)
        let csv = buildCSV(caseFile: caseFile, items: sortedEvidence)
        try csv.write(to: csvURL, atomically: true, encoding: .utf8)

        let hashURL = exportRoot.appendingPathComponent("hashes_sha256.txt", isDirectory: false)
        let hashList = buildHashList(items: sortedEvidence)
        try hashList.write(to: hashURL, atomically: true, encoding: .utf8)

        let reportURL = exportRoot.appendingPathComponent("01_Case_Report.pdf", isDirectory: false)
        let reportData = buildPDFReport(caseFile: caseFile, items: sortedEvidence)
        try reportData.write(to: reportURL, options: .atomic)

        // TODO: Add ZIP compression for export folder when deployment-target API support is finalized.
        return exportRoot
    }

    func exportPDFReport(for caseFile: CaseFile) throws -> URL {
        let exportContainer = try StorageLayout.exportsFolderURL(caseID: caseFile.id, fileManager: fileManager)
        let reportName = "Evidence Archive - \(SafeFilename.sanitizeStem(caseFile.title)) - Case Report.pdf"
        let reportURL = uniqueFileURL(baseFolder: exportContainer, preferredName: reportName)

        let sortedEvidence = sortedEvidenceItems(for: caseFile)
        let reportData = buildPDFReport(caseFile: caseFile, items: sortedEvidence)
        try reportData.write(to: reportURL, options: .atomic)
        return reportURL
    }

    private func sortedEvidenceItems(for caseFile: CaseFile) -> [EvidenceItem] {
        caseFile.evidenceList.sorted { lhs, rhs in
            if lhs.eventDate != rhs.eventDate { return lhs.eventDate > rhs.eventDate }
            return lhs.importedAt > rhs.importedAt
        }
    }

    private func buildCSV(caseFile: CaseFile, items: [EvidenceItem]) -> String {
        let headers = [
            "case_id",
            "case_title",
            "case_category",
            "evidence_id",
            "title",
            "evidence_type",
            "original_filename",
            "stored_filename",
            "event_date",
            "imported_at",
            "source",
            "note",
            "tags",
            "recognized_text",
            "sha256",
            "file_size",
            "type_identifier",
            "relative_file_path"
        ]

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var rows: [String] = [CSVEncoder.row(headers)]
        for item in items {
            rows.append(CSVEncoder.row([
                caseFile.id.uuidString,
                caseFile.title,
                caseFile.categoryRaw,
                item.id.uuidString,
                item.title,
                item.evidenceTypeRaw,
                item.originalFilename,
                item.storedFilename,
                formatter.string(from: item.eventDate),
                formatter.string(from: item.importedAt),
                item.source,
                item.note,
                item.tags,
                item.recognizedText,
                item.sha256,
                "\(item.fileSize)",
                item.typeIdentifier,
                item.relativeFilePath
            ]))
        }

        return rows.joined(separator: "\n") + "\n"
    }

    private func buildHashList(items: [EvidenceItem]) -> String {
        items
            .map { "\($0.sha256)  Evidence/\($0.storedFilename)" }
            .joined(separator: "\n") + "\n"
    }

    private func buildPDFReport(caseFile: CaseFile, items: [EvidenceItem]) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "\(L10n.text("Case Report")) - \(caseFile.title)",
            kCGPDFContextCreator as String: L10n.text("Evidence Archive")
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        return renderer.pdfData { context in
            let writer = CaseReportPDFWriter(context: context, pageRect: pageRect)
            writer.beginPage()
            writer.drawTitle(L10n.text("Evidence Archive"))
            writer.drawSubtitle(L10n.text("Case Report"))

            writer.drawSectionTitle(caseFile.title)
            writer.drawKeyValue(L10n.text("Category"), caseFile.category.localizedTitle)
            writer.drawKeyValue(L10n.text("Created"), writer.formatDate(caseFile.createdAt))
            writer.drawKeyValue(L10n.text("Updated"), writer.formatDate(caseFile.updatedAt))
            writer.drawKeyValue(L10n.text("Generated"), writer.formatDate(.now))
            writer.drawKeyValue(L10n.text("Evidence Count"), "\(items.count)")

            if !caseFile.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                writer.drawSectionTitle(L10n.text("Notes"))
                writer.drawBody(caseFile.notes)
            }

            writer.drawNotice(L10n.text("Case report disclaimer"))

            writer.drawSectionTitle(L10n.text("Timeline"))
            if items.isEmpty {
                writer.drawBody(L10n.text("No evidence items yet."))
            } else {
                for (index, item) in items.enumerated() {
                    writer.drawEvidenceItem(item, number: index + 1)
                }
            }
        }
    }

    private func uniqueFolderURL(baseFolder: URL, preferredName: String) -> URL {
        let initial = baseFolder.appendingPathComponent(preferredName, isDirectory: true)
        if !fileManager.fileExists(atPath: initial.path) {
            return initial
        }

        var idx = 2
        while true {
            let candidate = baseFolder.appendingPathComponent("\(preferredName) \(idx)", isDirectory: true)
            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
            idx += 1
        }
    }

    private func uniqueFileURL(baseFolder: URL, preferredName: String) -> URL {
        let initial = baseFolder.appendingPathComponent(preferredName, isDirectory: false)
        if !fileManager.fileExists(atPath: initial.path) {
            return initial
        }

        let split = SafeFilename.splitFilename(preferredName)
        var idx = 2
        while true {
            let candidateName = "\(split.stem) \(idx).\(split.ext)"
            let candidate = baseFolder.appendingPathComponent(candidateName, isDirectory: false)
            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
            idx += 1
        }
    }
}

private final class CaseReportPDFWriter {
    private let context: UIGraphicsPDFRendererContext
    private let pageRect: CGRect
    private let contentRect: CGRect
    private let topMargin: CGFloat = 48
    private let bottomMargin: CGFloat = 48

    private var cursorY: CGFloat = 48

    private let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
    private let subtitleFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
    private let sectionFont = UIFont.systemFont(ofSize: 15, weight: .bold)
    private let bodyFont = UIFont.systemFont(ofSize: 10.5, weight: .regular)
    private let labelFont = UIFont.systemFont(ofSize: 10.5, weight: .semibold)
    private let monoFont = UIFont.monospacedSystemFont(ofSize: 8.5, weight: .regular)

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    init(context: UIGraphicsPDFRendererContext, pageRect: CGRect) {
        self.context = context
        self.pageRect = pageRect
        self.contentRect = pageRect.insetBy(dx: 44, dy: 0)
    }

    func beginPage() {
        context.beginPage()
        cursorY = topMargin
    }

    func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    func drawTitle(_ text: String) {
        drawText(text, font: titleFont, color: .black, spacingAfter: 4)
    }

    func drawSubtitle(_ text: String) {
        drawText(text, font: subtitleFont, color: .darkGray, spacingAfter: 22)
    }

    func drawSectionTitle(_ text: String) {
        ensureSpace(28)
        drawText(text, font: sectionFont, color: .black, spacingBefore: 8, spacingAfter: 8)
    }

    func drawBody(_ text: String) {
        drawText(text, font: bodyFont, color: .darkGray, spacingAfter: 8)
    }

    func drawNotice(_ text: String) {
        ensureSpace(56)
        let rect = CGRect(
            x: contentRect.minX,
            y: cursorY,
            width: contentRect.width,
            height: 1
        )
        UIColor.systemGray4.setFill()
        UIRectFill(rect)
        cursorY += 12
        drawText(text, font: bodyFont, color: .darkGray, spacingAfter: 10)
    }

    func drawKeyValue(_ label: String, _ value: String) {
        let cleanValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanValue.isEmpty else { return }
        drawText("\(label): \(cleanValue)", font: bodyFont, color: .darkGray, spacingAfter: 4)
    }

    func drawEvidenceItem(_ item: EvidenceItem, number: Int) {
        ensureSpace(120)
        drawText("\(number). \(item.title)", font: sectionFont, color: .black, spacingBefore: 8, spacingAfter: 6)
        drawKeyValue(L10n.text("Type"), item.evidenceType.displayName)
        drawKeyValue(L10n.text("Event Date"), formatDate(item.eventDate))
        drawKeyValue(L10n.text("Imported"), formatDate(item.importedAt))
        drawKeyValue(L10n.text("Original Filename"), item.originalFilename)
        drawKeyValue(L10n.text("Stored Filename"), item.storedFilename)
        drawKeyValue(L10n.text("File Size"), ByteCountFormatter.string(fromByteCount: item.fileSize, countStyle: .file))
        drawKeyValue(L10n.text("Source"), item.source)
        drawKeyValue(L10n.text("Tags (comma separated)"), item.tags)

        if !item.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            drawText("\(L10n.text("Note")):", font: labelFont, color: .black, spacingBefore: 4, spacingAfter: 3)
            drawText(item.note, font: bodyFont, color: .darkGray, spacingAfter: 5)
        }

        if !item.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            drawText("\(L10n.text("Recognized Text")):", font: labelFont, color: .black, spacingBefore: 4, spacingAfter: 3)
            drawText(item.recognizedText, font: bodyFont, color: .darkGray, spacingAfter: 5)
        }

        drawText("SHA-256:", font: labelFont, color: .black, spacingBefore: 4, spacingAfter: 3)
        drawText(item.sha256, font: monoFont, color: .darkGray, spacingAfter: 10)
        drawDivider()
    }

    private func drawDivider() {
        ensureSpace(12)
        UIColor.systemGray5.setFill()
        UIRectFill(CGRect(x: contentRect.minX, y: cursorY, width: contentRect.width, height: 1))
        cursorY += 10
    }

    private func drawText(
        _ text: String,
        font: UIFont,
        color: UIColor,
        spacingBefore: CGFloat = 0,
        spacingAfter: CGFloat = 0
    ) {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        if spacingBefore > 0 {
            cursorY += spacingBefore
        }

        let paragraphs = normalized.components(separatedBy: "\n")
        for paragraph in paragraphs {
            drawParagraph(paragraph, font: font, color: color, spacingAfter: 2)
        }

        cursorY += spacingAfter
    }

    private func drawParagraph(
        _ paragraph: String,
        font: UIFont,
        color: UIColor,
        spacingAfter: CGFloat
    ) {
        let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            cursorY += font.lineHeight * 0.7
            return
        }

        var remaining = trimmed[...]
        while !remaining.isEmpty {
            let chunk = nextChunk(from: remaining)
            drawMeasuredText(String(chunk), font: font, color: color, spacingAfter: spacingAfter)
            remaining = remaining[chunk.endIndex...].drop(while: { $0.isWhitespace })
        }
    }

    private func nextChunk(from text: Substring) -> Substring {
        let maxLength = 900
        guard text.count > maxLength else { return text }

        let targetIndex = text.index(text.startIndex, offsetBy: maxLength)
        let candidate = text[..<targetIndex]
        if let splitIndex = candidate.lastIndex(where: { $0.isWhitespace }) {
            return text[..<splitIndex]
        }
        return candidate
    }

    private func drawMeasuredText(
        _ text: String,
        font: UIFont,
        color: UIColor,
        spacingAfter: CGFloat
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineSpacing = 1.5

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let maxSize = CGSize(width: contentRect.width, height: CGFloat.greatestFiniteMagnitude)
        let measured = attributed.boundingRect(
            with: maxSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let height = ceil(measured.height) + 1
        ensureSpace(height + spacingAfter)

        attributed.draw(in: CGRect(
            x: contentRect.minX,
            y: cursorY,
            width: contentRect.width,
            height: height
        ))
        cursorY += height + spacingAfter
    }

    private func ensureSpace(_ neededHeight: CGFloat) {
        if cursorY + neededHeight > pageRect.maxY - bottomMargin {
            beginPage()
        }
    }
}
