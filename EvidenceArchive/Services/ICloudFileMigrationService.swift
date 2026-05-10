import Foundation

enum ICloudFileMigrationService {
    static func migrateLocalEvidenceToICloudIfAvailable() {
        guard ICloudSyncConfig.isEnabled else { return }

        Task.detached(priority: .utility) {
            do {
                try migrateLocalEvidenceToICloud()
            } catch {
                #if DEBUG
                print("iCloud file migration skipped: \(error.localizedDescription)")
                #endif
            }
        }
    }

    private static func migrateLocalEvidenceToICloud(fileManager: FileManager = .default) throws {
        guard let iCloudDocumentsURL = ICloudSyncConfig.resolveUbiquityDocumentsURL(fileManager: fileManager) else {
            return
        }

        let localRoot = try AppGroupConfig.localRootContainerURL(fileManager: fileManager)
            .appendingPathComponent(AppGroupConfig.rootFolderName, isDirectory: true)
        let iCloudRoot = iCloudDocumentsURL
            .appendingPathComponent(AppGroupConfig.rootFolderName, isDirectory: true)

        guard localRoot.standardizedFileURL.path != iCloudRoot.standardizedFileURL.path,
              fileManager.fileExists(atPath: localRoot.path) else {
            return
        }

        try copyMissingItems(from: localRoot, to: iCloudRoot, fileManager: fileManager)
    }

    private static func copyMissingItems(
        from sourceURL: URL,
        to targetURL: URL,
        fileManager: FileManager
    ) throws {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory) else {
            return
        }

        if isDirectory.boolValue {
            try fileManager.createDirectory(at: targetURL, withIntermediateDirectories: true)
            let children = try fileManager.contentsOfDirectory(
                at: sourceURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            for child in children {
                let childTarget = targetURL.appendingPathComponent(child.lastPathComponent)
                try copyMissingItems(from: child, to: childTarget, fileManager: fileManager)
            }
            return
        }

        guard !fileManager.fileExists(atPath: targetURL.path) else {
            return
        }

        try fileManager.createDirectory(
            at: targetURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try fileManager.copyItem(at: sourceURL, to: targetURL)
    }
}
