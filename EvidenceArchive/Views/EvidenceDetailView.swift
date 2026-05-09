import SwiftData
import SwiftUI

struct EvidenceDetailView: View {
    @Environment(\.modelContext) private var modelContext

    @Bindable var evidence: EvidenceItem

    @State private var previewURL: URL?
    @State private var showingPreview = false
    @State private var showSavedBanner = false
    @State private var localError: String?

    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $evidence.title)
                LabeledContent("Type", value: evidence.evidenceType.displayName)
                LabeledContent("Original Filename", value: evidence.originalFilename)
                LabeledContent("Stored Filename", value: evidence.storedFilename)
                DatePicker("Event Date", selection: $evidence.eventDate)
                LabeledContent("Imported", value: evidence.importedAt.formatted(date: .abbreviated, time: .shortened))
                TextField("Source", text: $evidence.source)
            }

            Section("Notes & Tags") {
                TextEditor(text: $evidence.note)
                    .frame(minHeight: 120)
                TextField("Tags (comma separated)", text: $evidence.tags)
            }

            Section("Integrity") {
                Label("SHA-256 saved", systemImage: "checkmark.shield")
                    .foregroundStyle(.green)
                Text(evidence.sha256)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                LabeledContent("File Size", value: ByteCountFormatter.string(fromByteCount: evidence.fileSize, countStyle: .file))
                LabeledContent("Type Identifier", value: evidence.typeIdentifier)
                LabeledContent("Relative Path", value: evidence.relativeFilePath)
            }

            Section("File") {
                Button("Preview File") {
                    openPreview()
                }
                .disabled(previewURL == nil)

                if let previewURL {
                    ShareLink(item: previewURL) {
                        Label("Share/Export Original File", systemImage: "square.and.arrow.up")
                    }
                }

                Text("Direct file editing is disabled in this MVP.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(evidence.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveChanges()
                }
            }
        }
        .sheet(isPresented: $showingPreview) {
            if let previewURL {
                QuickLookPreview(url: previewURL)
            }
        }
        .onAppear {
            refreshPreviewURL()
        }
        .alert("Saved", isPresented: $showSavedBanner) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Evidence metadata updated.")
        }
        .alert("Error", isPresented: Binding(
            get: { localError != nil },
            set: { if !$0 { localError = nil } }
        )) {
            Button("OK", role: .cancel) {
                localError = nil
            }
        } message: {
            Text(localError ?? "Unknown error")
        }
    }

    private func saveChanges() {
        do {
            evidence.caseFile?.updatedAt = .now
            try modelContext.save()
            showSavedBanner = true
        } catch {
            localError = error.localizedDescription
        }
    }

    private func openPreview() {
        guard previewURL != nil else { return }
        showingPreview = true
    }

    private func refreshPreviewURL() {
        do {
            previewURL = try StorageLayout.storedFileURL(for: evidence)
        } catch {
            previewURL = nil
            localError = error.localizedDescription
        }
    }
}
