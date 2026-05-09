import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct AddEvidenceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var store: EvidenceStore

    let caseFile: CaseFile

    @State private var showFileImporter = false
    @State private var photoItems: [PhotosPickerItem] = []

    @State private var sourceLabel = L10n.text("Manual Import")
    @State private var tags = ""
    @State private var commonNote = ""
    @State private var eventDate = Date()

    @State private var noteTitle = ""
    @State private var noteContent = ""

    private let supportedTypes: [UTType] = [
        .pdf,
        .image,
        .audio,
        .video,
        .plainText,
        .zip,
        .data
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Metadata") {
                    TextField("Source", text: $sourceLabel)
                    TextField("Tags (comma separated)", text: $tags)
                    DatePicker("Event Date", selection: $eventDate)
                    TextField("Note", text: $commonNote, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section("Import Files") {
                    Button {
                        showFileImporter = true
                    } label: {
                        Label("Add from Files", systemImage: "folder")
                    }

                    PhotosPicker(
                        selection: $photoItems,
                        maxSelectionCount: 30,
                        matching: .any(of: [.images, .videos])
                    ) {
                        Label("Add from Photos", systemImage: "photo.on.rectangle")
                    }
                }

                Section("Text Note") {
                    TextField("Note Title", text: $noteTitle)
                    TextEditor(text: $noteContent)
                        .frame(minHeight: 120)

                    Button {
                        Task {
                            await store.addTextNoteEvidence(
                                into: caseFile,
                                title: noteTitle,
                                note: noteContent,
                                sourceLabel: sourceLabel,
                                tags: tags,
                                eventDate: eventDate,
                                context: modelContext
                            )
                            dismissIfNoError()
                        }
                    } label: {
                        Label("Save Text Note as Evidence", systemImage: "square.and.pencil")
                    }
                    .disabled(noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Add Evidence")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if store.isBusy {
                    ProgressView("Importing…")
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: supportedTypes,
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    Task {
                        await store.importFiles(
                            urls: urls,
                            into: caseFile,
                            sourceLabel: sourceLabel,
                            note: commonNote,
                            tags: tags,
                            eventDate: eventDate,
                            context: modelContext
                        )
                        dismissIfNoError()
                    }
                case .failure(let error):
                    store.lastError = error.localizedDescription
                }
            }
            .onChange(of: photoItems) { _, newItems in
                guard !newItems.isEmpty else { return }
                Task {
                    var payloads: [EvidenceStore.DataImportPayload] = []

                    for (index, item) in newItems.enumerated() {
                        guard let data = try? await item.loadTransferable(type: Data.self) else {
                            continue
                        }
                        let preferredType = item.supportedContentTypes.first
                        let ext = preferredType?.preferredFilenameExtension ?? "bin"
                        let filename = "Photo_\(Int(Date().timeIntervalSince1970))_\(index).\(ext)"
                        payloads.append(
                            EvidenceStore.DataImportPayload(
                                data: data,
                                suggestedFilename: filename,
                                typeIdentifier: preferredType?.identifier
                            )
                        )
                    }

                    await store.importPayloads(
                        payloads,
                        into: caseFile,
                        sourceLabel: sourceLabel,
                        note: commonNote,
                        tags: tags,
                        eventDate: eventDate,
                        context: modelContext
                    )
                    photoItems = []
                    dismissIfNoError()
                }
            }
        }
    }

    private func dismissIfNoError() {
        if store.lastError == nil {
            dismiss()
        }
    }
}
