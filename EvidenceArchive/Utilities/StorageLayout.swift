import Foundation

enum StorageLayout {
    static func casesRootURL(fileManager: FileManager = .default) throws -> URL {
        try AppGroupConfig.casesRootURL(fileManager: fileManager)
    }

    static func caseRootURL(caseID: UUID, fileManager: FileManager = .default) throws -> URL {
        try casesRootURL(fileManager: fileManager)
            .appendingPathComponent(caseID.uuidString, isDirectory: true)
    }

    static func evidenceFolderURL(caseID: UUID, fileManager: FileManager = .default) throws -> URL {
        let url = try caseRootURL(caseID: caseID, fileManager: fileManager)
            .appendingPathComponent("evidence", isDirectory: true)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func thumbnailsFolderURL(caseID: UUID, fileManager: FileManager = .default) throws -> URL {
        let url = try caseRootURL(caseID: caseID, fileManager: fileManager)
            .appendingPathComponent("thumbnails", isDirectory: true)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func exportsFolderURL(caseID: UUID, fileManager: FileManager = .default) throws -> URL {
        let url = try caseRootURL(caseID: caseID, fileManager: fileManager)
            .appendingPathComponent("exports", isDirectory: true)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func storedFileURL(for evidence: EvidenceItem, fileManager: FileManager = .default) throws -> URL {
        guard let caseID = evidence.caseFile?.id else {
            throw EvidenceError.fileNotFound
        }
        return try evidenceFolderURL(caseID: caseID, fileManager: fileManager)
            .appendingPathComponent(evidence.storedFilename, isDirectory: false)
    }
}
