import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Evidence Archive") {
                    Text("Local evidence archive for structured documentation on iPhone and iPad.")
                }

                Section("Privacy") {
                    Text("Evidence Archive stores your files locally on this device unless you explicitly export or share them. No cloud upload is performed by this app.")
                }

                Section("Integrity") {
                    Text("SHA-256 hashes can help verify file integrity after import. This app does not provide legal advice and does not guarantee admissibility of evidence.")
                }

                Section("Storage") {
                    Text("Files are saved in Application Support/EvidenceArchive/Cases/<caseUUID>/...")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("About")
        }
    }
}
