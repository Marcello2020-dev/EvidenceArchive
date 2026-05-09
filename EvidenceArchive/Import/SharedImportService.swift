import Foundation
import SwiftData

/// Shared importer API designed for both the main app and a future Share Extension.
@MainActor
final class SharedImportService {
    private let fileImportService: FileImportService

    init(fileImportService: FileImportService = FileImportService()) {
        self.fileImportService = fileImportService
    }

    func importFileURLs(
        _ urls: [URL],
        into caseFile: CaseFile,
        sourceLabel: String,
        note: String,
        tags: String,
        eventDate: Date?,
        context: ModelContext
    ) async throws -> Int {
        var insertedCount = 0

        for url in urls {
            let imported = try await fileImportService.importFile(
                from: url,
                caseID: caseFile.id,
                preferredEventDate: eventDate
            )

            let item = EvidenceItem(
                caseID: caseFile.id,
                title: imported.title,
                evidenceType: imported.evidenceType,
                originalFilename: imported.originalFilename,
                storedFilename: imported.storedFilename,
                eventDate: imported.eventDate,
                importedAt: imported.importedAt,
                source: sourceLabel,
                note: note,
                tags: tags,
                sha256: imported.sha256,
                fileSize: imported.fileSize,
                typeIdentifier: imported.typeIdentifier,
                relativeFilePath: imported.relativeFilePath,
                caseFile: caseFile
            )
            context.insert(item)
            insertedCount += 1
        }

        caseFile.updatedAt = .now
        try context.save()
        return insertedCount
    }

    func createCaseIfNeeded(
        title: String,
        category: CaseCategory = .privateCase,
        notes: String = "",
        context: ModelContext
    ) throws -> CaseFile {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw EvidenceError.invalidCaseTitle
        }

        let caseFile = CaseFile(title: trimmed, category: category, notes: notes)
        context.insert(caseFile)
        try context.save()
        return caseFile
    }
}
