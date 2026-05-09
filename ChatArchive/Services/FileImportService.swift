import Foundation
import UniformTypeIdentifiers

actor FileImportService {
    struct CaseDirectories {
        let caseRoot: URL
        let evidence: URL
        let thumbnails: URL
        let exports: URL
    }

    struct ImportedEvidenceFile {
        let title: String
        let evidenceType: EvidenceType
        let originalFilename: String
        let storedFilename: String
        let eventDate: Date
        let importedAt: Date
        let sha256: String
        let fileSize: Int64
        let typeIdentifier: String
        let relativeFilePath: String
    }

    private let fileManager: FileManager
    private let hashService: HashService

    init(fileManager: FileManager = .default, hashService: HashService = HashService()) {
        self.fileManager = fileManager
        self.hashService = hashService
    }

    func caseDirectories(for caseID: UUID) throws -> CaseDirectories {
        let caseRoot = try StorageLayout.caseRootURL(caseID: caseID, fileManager: fileManager)
        let evidence = try StorageLayout.evidenceFolderURL(caseID: caseID, fileManager: fileManager)
        let thumbnails = try StorageLayout.thumbnailsFolderURL(caseID: caseID, fileManager: fileManager)
        let exports = try StorageLayout.exportsFolderURL(caseID: caseID, fileManager: fileManager)

        return CaseDirectories(caseRoot: caseRoot, evidence: evidence, thumbnails: thumbnails, exports: exports)
    }

    func storedFileURL(for evidence: EvidenceItem) throws -> URL {
        try StorageLayout.storedFileURL(for: evidence, fileManager: fileManager)
    }

    func importFile(
        from sourceURL: URL,
        caseID: UUID,
        preferredEventDate: Date?
    ) throws -> ImportedEvidenceFile {
        let access = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if access {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let directories = try caseDirectories(for: caseID)
        let importedAt = Date()
        let eventDate = preferredEventDate ?? importedAt
        let originalFilename = sourceURL.lastPathComponent

        let existingNames = try Set(
            fileManager.contentsOfDirectory(atPath: directories.evidence.path)
                .map { $0.lowercased() }
        )
        let storedFilename = SafeFilename.makeStoredFilename(
            originalFilename: originalFilename,
            eventDate: eventDate,
            existingNames: existingNames
        )
        let destinationURL = directories.evidence.appendingPathComponent(storedFilename, isDirectory: false)

        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            throw EvidenceError.importFailed(error.localizedDescription)
        }

        let fileSize = Int64((try? destinationURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        let typeIdentifier = resolveTypeIdentifier(sourceURL: sourceURL, destinationURL: destinationURL)
        let evidenceType = EvidenceType.infer(from: typeIdentifier)
        let sha256 = try hashService.sha256Hex(forFileAt: destinationURL)
        let relativeFilePath = "\(AppGroupConfig.casesFolderName)/\(caseID.uuidString)/evidence/\(storedFilename)"

        let title = SafeFilename.splitFilename(originalFilename).stem

        return ImportedEvidenceFile(
            title: title,
            evidenceType: evidenceType,
            originalFilename: originalFilename,
            storedFilename: storedFilename,
            eventDate: eventDate,
            importedAt: importedAt,
            sha256: sha256,
            fileSize: fileSize,
            typeIdentifier: typeIdentifier,
            relativeFilePath: relativeFilePath
        )
    }

    func importData(
        _ data: Data,
        suggestedFilename: String,
        caseID: UUID,
        preferredEventDate: Date?,
        typeIdentifier: String?
    ) throws -> ImportedEvidenceFile {
        let directories = try caseDirectories(for: caseID)
        let importedAt = Date()
        let eventDate = preferredEventDate ?? importedAt

        let existingNames = try Set(
            fileManager.contentsOfDirectory(atPath: directories.evidence.path)
                .map { $0.lowercased() }
        )

        let storedFilename = SafeFilename.makeStoredFilename(
            originalFilename: suggestedFilename,
            eventDate: eventDate,
            existingNames: existingNames
        )

        let destinationURL = directories.evidence.appendingPathComponent(storedFilename, isDirectory: false)
        do {
            try data.write(to: destinationURL, options: .atomic)
        } catch {
            throw EvidenceError.importFailed(error.localizedDescription)
        }

        let resolvedType = typeIdentifier
            ?? UTType(filenameExtension: destinationURL.pathExtension)?.identifier
            ?? UTType.data.identifier

        let evidenceType = EvidenceType.infer(from: resolvedType)
        let sha256 = try hashService.sha256Hex(forFileAt: destinationURL)
        let fileSize = Int64(data.count)
        let relativeFilePath = "\(AppGroupConfig.casesFolderName)/\(caseID.uuidString)/evidence/\(storedFilename)"
        let title = SafeFilename.splitFilename(suggestedFilename).stem

        return ImportedEvidenceFile(
            title: title,
            evidenceType: evidenceType,
            originalFilename: suggestedFilename,
            storedFilename: storedFilename,
            eventDate: eventDate,
            importedAt: importedAt,
            sha256: sha256,
            fileSize: fileSize,
            typeIdentifier: resolvedType,
            relativeFilePath: relativeFilePath
        )
    }

    private func resolveTypeIdentifier(sourceURL: URL, destinationURL: URL) -> String {
        if let fromResource = try? sourceURL.resourceValues(forKeys: [.contentTypeKey]).contentType?.identifier {
            return fromResource
        }

        if let fromExt = UTType(filenameExtension: destinationURL.pathExtension)?.identifier {
            return fromExt
        }

        return UTType.data.identifier
    }
}
