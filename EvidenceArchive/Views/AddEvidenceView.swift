import PhotosUI
import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import VisionKit

struct AddEvidenceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var store: EvidenceStore
    @EnvironmentObject private var purchaseService: PurchaseService

    let caseFile: CaseFile

    @State private var showFileImporter = false
    @State private var showCameraCapture = false
    @State private var showDocumentScanner = false
    @State private var showTextScanner = false
    @State private var showPaywall = false
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

                if FreeUsageLimits.isEnabled && !purchaseService.hasFullAccess {
                    Section("Free Plan") {
                        HStack(spacing: 12) {
                            IconBadge(systemName: "lock", color: .orange, size: 34)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(freePlanStatusText)
                                    .font(.subheadline.weight(.medium))
                                Text("Unlock to add unlimited case files and evidence items.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button {
                            showPaywall = true
                        } label: {
                            Label("Unlock Full Version", systemImage: "lock.open")
                        }
                    }
                }

                Section("Import Files") {
                    Button {
                        if canImportEvidence(count: 1) {
                            showFileImporter = true
                        }
                    } label: {
                        ImportActionLabel(
                            title: L10n.text("Add from Files"),
                            systemName: "folder",
                            color: .blue
                        )
                    }

                    PhotosPicker(
                        selection: $photoItems,
                        maxSelectionCount: 30,
                        matching: .any(of: [.images, .videos])
                    ) {
                        ImportActionLabel(
                            title: L10n.text("Add from Photos"),
                            systemName: "photo.on.rectangle",
                            color: .cyan
                        )
                    }
                }

                Section("Capture Evidence") {
                    Button {
                        if canImportEvidence(count: 1) {
                            showCameraCapture = true
                        }
                    } label: {
                        ImportActionLabel(
                            title: L10n.text("Take Photo"),
                            systemName: "camera",
                            color: .orange
                        )
                    }
                    .disabled(!isCameraCaptureAvailable)

                    Button {
                        if canImportEvidence(count: 1) {
                            showDocumentScanner = true
                        }
                    } label: {
                        ImportActionLabel(
                            title: L10n.text("Scan Document"),
                            systemName: "doc.viewfinder",
                            color: .green
                        )
                    }
                    .disabled(!isDocumentScannerAvailable)

                    Button {
                        if canImportEvidence(count: 1) {
                            showTextScanner = true
                        }
                    } label: {
                        ImportActionLabel(
                            title: L10n.text("Scan Text"),
                            systemName: "text.viewfinder",
                            color: .indigo
                        )
                    }
                    .disabled(!isTextScannerAvailable)

                    if let unavailableCaptureMessage {
                        Text(unavailableCaptureMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if !isTextScannerAvailable {
                        Text("Text scanner is not available on this device.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Text Note") {
                    TextField("Note Title", text: $noteTitle)
                    TextEditor(text: $noteContent)
                        .frame(minHeight: 120)

                    Button {
                        guard canImportEvidence(count: 1) else { return }
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
                        ImportActionLabel(
                            title: L10n.text("Save Text Note as Evidence"),
                            systemName: "square.and.pencil",
                            color: .purple
                        )
                    }
                    .disabled(noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .scrollContentBackground(.hidden)
            .evidenceScreenBackground()
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
                    guard canImportEvidence(count: urls.count) else { return }
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
            .fullScreenCover(isPresented: $showCameraCapture) {
                CameraCaptureView { result in
                    switch result {
                    case .success(let image):
                        importCapturedPhoto(image)
                    case .failure(let error):
                        store.lastError = error.localizedDescription
                    }
                }
            }
            .fullScreenCover(isPresented: $showDocumentScanner) {
                DocumentScannerView { result in
                    switch result {
                    case .success(let payload):
                        importCapturePayload(payload)
                    case .failure(let error):
                        store.lastError = error.localizedDescription
                    }
                }
            }
            .fullScreenCover(isPresented: $showTextScanner) {
                TextScannerSheet { text in
                    importScannedText(text)
                }
            }
            .onChange(of: photoItems) { _, newItems in
                guard !newItems.isEmpty else { return }
                guard canImportEvidence(count: newItems.count) else {
                    photoItems = []
                    return
                }
                Task {
                    var payloads: [EvidenceStore.DataImportPayload] = []

                    for (index, item) in newItems.enumerated() {
                        guard let data = try? await item.loadTransferable(type: Data.self) else {
                            continue
                        }
                        let preferredType = item.supportedContentTypes.first
                        let ext = preferredType?.preferredFilenameExtension ?? "bin"
                        let filename = "Photo_\(Int(Date().timeIntervalSince1970))_\(index).\(ext)"
                        let recognizedText = TextRecognitionService.recognizeText(
                            in: data,
                            typeIdentifier: preferredType?.identifier
                        )

                        payloads.append(
                            EvidenceStore.DataImportPayload(
                                data: data,
                                suggestedFilename: filename,
                                typeIdentifier: preferredType?.identifier,
                                recognizedText: recognizedText
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
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var freePlanStatusText: String {
        L10n.format(
            "%lld of %lld free evidence items used in this case.",
            Int64(caseFile.evidenceCount),
            Int64(FreeUsageLimits.maxEvidenceItemsPerCase)
        )
    }

    private var isCameraCaptureAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    private var isDocumentScannerAvailable: Bool {
        VNDocumentCameraViewController.isSupported
    }

    private var isTextScannerAvailable: Bool {
        TextScannerView.isAvailable
    }

    private var unavailableCaptureMessage: String? {
        switch (isCameraCaptureAvailable, isDocumentScannerAvailable) {
        case (true, true):
            return nil
        case (false, true):
            return L10n.text("Camera capture is not available on this device.")
        case (true, false):
            return L10n.text("Document scanning is not available on this device.")
        case (false, false):
            return L10n.text("Camera capture and document scanning are not available on this device.")
        }
    }

    private func importCapturedPhoto(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.92) else {
            store.lastError = EvidenceError.importFailed(L10n.text("Could not create image data.")).localizedDescription
            return
        }

        let payload = EvidenceStore.DataImportPayload(
            data: data,
            suggestedFilename: "\(L10n.text("Captured Photo")) \(filenameTimestamp()).jpg",
            typeIdentifier: UTType.jpeg.identifier,
            recognizedText: TextRecognitionService.recognizeText(in: image)
        )
        importCapturePayload(payload)
    }

    private func importCapturePayload(_ payload: EvidenceStore.DataImportPayload) {
        guard canImportEvidence(count: 1) else { return }
        Task {
            await store.importPayloads(
                [payload],
                into: caseFile,
                sourceLabel: sourceLabel,
                note: commonNote,
                tags: tags,
                eventDate: eventDate,
                context: modelContext
            )
            dismissIfNoError()
        }
    }

    private func importScannedText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canImportEvidence(count: 1) else { return }

        Task {
            await store.addTextNoteEvidence(
                into: caseFile,
                title: L10n.text("Scanned Text"),
                note: trimmed,
                sourceLabel: L10n.text("VisionKit Text Scanner"),
                tags: tags,
                eventDate: eventDate,
                recognizedText: trimmed,
                context: modelContext
            )
            dismissIfNoError()
        }
    }

    private func canImportEvidence(count: Int) -> Bool {
        if FreeUsageLimits.canAddEvidence(
            currentEvidenceCount: caseFile.evidenceCount,
            adding: count,
            hasFullAccess: purchaseService.hasFullAccess
        ) {
            return true
        }

        showPaywall = true
        return false
    }

    private func filenameTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }

    private func dismissIfNoError() {
        if store.lastError == nil {
            dismiss()
        }
    }
}

private struct TextScannerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var recognizedText = ""
    @State private var scannerError: String?

    let onSave: (String) -> Void

    private var trimmedText: String {
        recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if TextScannerView.isAvailable {
                    TextScannerView(
                        recognizedText: $recognizedText,
                        scannerError: $scannerError
                    )
                    .ignoresSafeArea()
                } else {
                    ContentUnavailableView(
                        L10n.text("Text Scanner"),
                        systemImage: "text.viewfinder",
                        description: Text("Text scanner is not available on this device.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .evidenceScreenBackground()
                }

                VStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Recognized Text", systemImage: "text.viewfinder")
                                .font(.headline)
                            Spacer()
                        }

                        ScrollView {
                            Text(trimmedText.isEmpty ? L10n.text("No text detected yet.") : trimmedText)
                                .font(.subheadline)
                                .foregroundStyle(trimmedText.isEmpty ? .secondary : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .frame(maxHeight: 120)

                        if let scannerError {
                            Text(scannerError)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        } else {
                            Text("Point the camera at text. Detected text will appear here.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            onSave(trimmedText)
                            dismiss()
                        } label: {
                            Label("Save Scanned Text", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(trimmedText.isEmpty)
                    }
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding()
                }
            }
            .navigationTitle("Scan Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
