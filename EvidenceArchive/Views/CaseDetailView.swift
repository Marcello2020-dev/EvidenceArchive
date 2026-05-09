import SwiftUI

struct CaseDetailView: View {
    enum SortMode: String, CaseIterable, Identifiable {
        case newest
        case oldest

        var id: String { rawValue }

        var localizedTitle: String {
            switch self {
            case .newest:
                return L10n.text("Newest")
            case .oldest:
                return L10n.text("Oldest")
            }
        }
    }

    struct ExportArtifact: Identifiable {
        let id = UUID()
        let url: URL
    }

    @EnvironmentObject private var store: EvidenceStore

    @State private var searchText = ""
    @State private var sortMode: SortMode = .newest
    @State private var showingAddEvidence = false
    @State private var exportArtifact: ExportArtifact?

    @Bindable var caseFile: CaseFile

    private var filteredItems: [EvidenceItem] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let scoped = caseFile.evidenceItems.filter { item in
            guard !needle.isEmpty else { return true }
            return item.title.localizedCaseInsensitiveContains(needle)
                || item.note.localizedCaseInsensitiveContains(needle)
                || item.tags.localizedCaseInsensitiveContains(needle)
                || item.originalFilename.localizedCaseInsensitiveContains(needle)
                || item.source.localizedCaseInsensitiveContains(needle)
        }

        return scoped.sorted { lhs, rhs in
            let compareByDate: Bool
            if lhs.eventDate != rhs.eventDate {
                compareByDate = sortMode == .newest ? lhs.eventDate > rhs.eventDate : lhs.eventDate < rhs.eventDate
            } else {
                compareByDate = sortMode == .newest ? lhs.importedAt > rhs.importedAt : lhs.importedAt < rhs.importedAt
            }
            return compareByDate
        }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Label(caseFile.category.localizedTitle, systemImage: "folder")
                    Spacer()
                    Text(L10n.format("%lld items", Int64(caseFile.evidenceItems.count)))
                        .foregroundStyle(.secondary)
                }

                if !caseFile.notes.isEmpty {
                    Text(caseFile.notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Picker("Sort", selection: $sortMode) {
                    ForEach(SortMode.allCases) { mode in
                        Text(mode.localizedTitle).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Timeline") {
                if filteredItems.isEmpty {
                    Text("No evidence items yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredItems) { item in
                        NavigationLink {
                            EvidenceDetailView(evidence: item)
                        } label: {
                            EvidenceRow(item: item)
                        }
                    }
                }
            }

            if let artifact = exportArtifact {
                Section("Latest Export") {
                    Text(artifact.url.lastPathComponent)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    ShareLink(item: artifact.url) {
                        Label("Share Export Folder", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .navigationTitle(caseFile.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search title, note, tags")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    exportCase()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }

                Button {
                    showingAddEvidence = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddEvidence) {
            AddEvidenceView(caseFile: caseFile)
        }
    }

    private func exportCase() {
        if let url = store.exportCase(caseFile) {
            exportArtifact = ExportArtifact(url: url)
        }
    }
}

private struct EvidenceRow: View {
    let item: EvidenceItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(item.title, systemImage: item.evidenceType.iconName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(item.eventDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Text(item.evidenceType.displayName)
                Text(ByteCountFormatter.string(fromByteCount: item.fileSize, countStyle: .file))
                Label("SHA-256 saved", systemImage: "checkmark.shield")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !item.note.isEmpty {
                Text(item.note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
