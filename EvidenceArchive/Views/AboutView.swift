import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Evidence Archive") {
                    Text("Local evidence archive for structured documentation on iPhone and iPad.")
                }

                Section("Privacy") {
                    Text("Evidence Archive processes files on this device. With iCloud sync enabled, Apple iCloud may sync case metadata and evidence files between devices signed in to your Apple ID. The app does not use accounts or third-party uploads.")
                }

                Section("iCloud Sync") {
                    Text("Case metadata syncs through a private CloudKit database. Evidence files are stored in the app's iCloud Drive container when iCloud is available; otherwise the app falls back to local device storage.")
                }

                Section("Integrity") {
                    Text("SHA-256 hashes can help verify file integrity after import. This app does not provide legal advice and does not guarantee admissibility of evidence.")
                }

                Section("Storage") {
                    Text("Files are saved under EvidenceArchive/Cases/<caseUUID>/... in iCloud Drive when available, with Application Support as the local fallback.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("About")
        }
    }
}
