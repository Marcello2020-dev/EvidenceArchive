import Foundation
import SwiftData

/// Centralized iCloud configuration for metadata and evidence file sync.
///
/// IMPORTANT:
/// 1) Enable iCloud manually in Signing & Capabilities.
/// 2) Enable both CloudKit and iCloud Documents for the app target.
/// 3) Create/assign the container identifier below in Certificates, Identifiers & Profiles.
enum ICloudSyncConfig {
    static let isEnabled = true
    static let cloudKitContainerIdentifier = "iCloud.dev.marcello2020.evidencearchive"
    static let ubiquityContainerIdentifier: String? = cloudKitContainerIdentifier
    static let documentsFolderName = "Documents"

    private static let cacheLock = NSLock()
    private static var cachedDocumentsURL: URL?

    static var cloudKitDatabase: ModelConfiguration.CloudKitDatabase {
        isEnabled ? .private(cloudKitContainerIdentifier) : .none
    }

    static func prepareUbiquityContainer(fileManager: FileManager = .default) {
        guard isEnabled else { return }

        Task.detached(priority: .utility) {
            _ = resolveUbiquityDocumentsURL(fileManager: fileManager)
        }
    }

    static func cachedUbiquityDocumentsURL() -> URL? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return cachedDocumentsURL
    }

    /// Call from a background thread. FileManager may take time to establish iCloud access.
    static func resolveUbiquityDocumentsURL(fileManager: FileManager = .default) -> URL? {
        guard isEnabled,
              let containerURL = fileManager.url(forUbiquityContainerIdentifier: ubiquityContainerIdentifier) else {
            return nil
        }

        let documentsURL = containerURL.appendingPathComponent(documentsFolderName, isDirectory: true)
        try? fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        cacheLock.lock()
        cachedDocumentsURL = documentsURL
        cacheLock.unlock()
        return documentsURL
    }
}
