import Foundation
import SwiftData

@MainActor
final class EvidenceStore: ObservableObject {
    struct DataImportPayload {
        let data: Data
        let suggestedFilename: String
        let typeIdentifier: String?
    }

    @Published var isBusy = false
    @Published var lastMessage: String?
    @Published var lastError: String?

    private let importService: FileImportService
    private let exportService: ExportService

    init(
        importService: FileImportService = FileImportService(),
        exportService: ExportService = ExportService()
    ) {
        self.importService = importService
        self.exportService = exportService
    }

    func createCase(
        title: String,
        category: CaseCategory,
        notes: String,
        context: ModelContext
    ) throws {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw EvidenceError.invalidCaseTitle
        }

        let caseFile = CaseFile(title: trimmed, category: category, notes: notes)
        context.insert(caseFile)
        try context.save()
        lastMessage = L10n.text("Case created.")
    }

    func updateCase(
        _ caseFile: CaseFile,
        title: String,
        category: CaseCategory,
        notes: String,
        context: ModelContext
    ) throws {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw EvidenceError.invalidCaseTitle
        }

        caseFile.title = trimmed
        caseFile.category = category
        caseFile.notes = notes
        caseFile.updatedAt = .now
        try context.save()
        lastMessage = L10n.text("Case updated.")
    }

    func deleteCase(_ caseFile: CaseFile, context: ModelContext) throws {
        context.delete(caseFile)
        try context.save()
        lastMessage = L10n.text("Case deleted.")
    }

    func importFiles(
        urls: [URL],
        into caseFile: CaseFile,
        sourceLabel: String,
        note: String,
        tags: String,
        eventDate: Date?,
        context: ModelContext
    ) async {
        guard !urls.isEmpty else { return }
        isBusy = true
        defer { isBusy = false }

        do {
            for url in urls {
                let imported = try await importService.importFile(
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
            }

            caseFile.updatedAt = .now
            try context.save()
            lastMessage = L10n.format("Imported %lld file(s).", Int64(urls.count))
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func importPayloads(
        _ payloads: [DataImportPayload],
        into caseFile: CaseFile,
        sourceLabel: String,
        note: String,
        tags: String,
        eventDate: Date?,
        context: ModelContext
    ) async {
        guard !payloads.isEmpty else { return }
        isBusy = true
        defer { isBusy = false }

        do {
            for payload in payloads {
                let imported = try await importService.importData(
                    payload.data,
                    suggestedFilename: payload.suggestedFilename,
                    caseID: caseFile.id,
                    preferredEventDate: eventDate,
                    typeIdentifier: payload.typeIdentifier
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
            }

            caseFile.updatedAt = .now
            try context.save()
            lastMessage = L10n.format("Imported %lld item(s).", Int64(payloads.count))
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func addTextNoteEvidence(
        into caseFile: CaseFile,
        title: String,
        note: String,
        sourceLabel: String,
        tags: String,
        eventDate: Date?,
        context: ModelContext
    ) async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? L10n.text("Text Note") : trimmedTitle

        let payload = DataImportPayload(
            data: Data(note.utf8),
            suggestedFilename: "\(finalTitle).txt",
            typeIdentifier: "public.plain-text"
        )

        await importPayloads(
            [payload],
            into: caseFile,
            sourceLabel: sourceLabel,
            note: note,
            tags: tags,
            eventDate: eventDate,
            context: context
        )
    }

    func exportCase(_ caseFile: CaseFile) -> URL? {
        do {
            let url = try exportService.exportFolder(for: caseFile)
            lastMessage = L10n.text("Export ready.")
            lastError = nil
            return url
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }
}
