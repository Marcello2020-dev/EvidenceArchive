import Foundation

/// Centralized app group configuration for both app and share extension targets.
///
/// IMPORTANT:
/// 1) Enable App Groups manually in Signing & Capabilities for all participating targets.
/// 2) Set `useAppGroupContainer = true` once capabilities are active.
enum AppGroupConfig {
    static let groupIdentifier = "group.com.example.EvidenceArchive"
    static let useAppGroupContainer = false

    static let rootFolderName = "EvidenceArchive"
    static let casesFolderName = "Cases"

    static func localRootContainerURL(fileManager: FileManager = .default) throws -> URL {
        try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    static func appGroupRootContainerURL(fileManager: FileManager = .default) -> URL? {
        if useAppGroupContainer,
           let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) {
            return groupURL
        }

        return nil
    }

    static func rootContainerURL(fileManager: FileManager = .default) throws -> URL {
        if let iCloudURL = ICloudSyncConfig.cachedUbiquityDocumentsURL() {
            return iCloudURL
        }

        if let groupURL = appGroupRootContainerURL(fileManager: fileManager) {
            return groupURL
        }

        return try localRootContainerURL(fileManager: fileManager)
    }

    static func evidenceRootURL(fileManager: FileManager = .default) throws -> URL {
        let root = try rootContainerURL(fileManager: fileManager)
            .appendingPathComponent(rootFolderName, isDirectory: true)
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    static func casesRootURL(fileManager: FileManager = .default) throws -> URL {
        let cases = try evidenceRootURL(fileManager: fileManager)
            .appendingPathComponent(casesFolderName, isDirectory: true)
        try fileManager.createDirectory(at: cases, withIntermediateDirectories: true)
        return cases
    }
}
