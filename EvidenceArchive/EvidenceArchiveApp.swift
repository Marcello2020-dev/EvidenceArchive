import SwiftData
import SwiftUI

@main
struct EvidenceArchiveApp: App {
    @StateObject private var evidenceStore = EvidenceStore()
    @StateObject private var purchaseService = PurchaseService()

    private let modelContainer = Self.makeModelContainer()

    init() {
        ICloudSyncConfig.prepareUbiquityContainer()
        ICloudFileMigrationService.migrateLocalEvidenceToICloudIfAvailable()
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([CaseFile.self, EvidenceItem.self])

        do {
            let cloudConfig = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: ICloudSyncConfig.cloudKitDatabase
            )
            return try ModelContainer(for: schema, configurations: cloudConfig)
        } catch {
            do {
                let localConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
                return try ModelContainer(for: schema, configurations: localConfig)
            } catch {
                do {
                    let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                    return try ModelContainer(for: schema, configurations: fallbackConfig)
                } catch {
                    preconditionFailure("Failed to initialize model container: \(error.localizedDescription)")
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(evidenceStore)
                .environmentObject(purchaseService)
        }
        .modelContainer(modelContainer)
    }
}
