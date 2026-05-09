import SwiftData
import SwiftUI

@main
struct EvidenceArchiveApp: App {
    @StateObject private var evidenceStore = EvidenceStore()

    private let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: CaseFile.self, EvidenceItem.self)
        } catch {
            do {
                let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                return try ModelContainer(
                    for: CaseFile.self,
                    EvidenceItem.self,
                    configurations: fallbackConfig
                )
            } catch {
                preconditionFailure("Failed to initialize model container: \(error.localizedDescription)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(evidenceStore)
        }
        .modelContainer(modelContainer)
    }
}
