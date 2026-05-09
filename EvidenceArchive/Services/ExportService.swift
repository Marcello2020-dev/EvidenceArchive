import Foundation

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

        let sortedEvidence = caseFile.evidenceItems.sorted { lhs, rhs in
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

        // TODO: Add ZIP compression for export folder when deployment-target API support is finalized.
        return exportRoot
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
}
