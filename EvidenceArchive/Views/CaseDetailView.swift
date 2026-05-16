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
    @EnvironmentObject private var purchaseService: PurchaseService
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var sortMode: SortMode = .newest
    @State private var showingAddEvidence = false
    @State private var showingPaywall = false
    @State private var exportArtifact: ExportArtifact?
    @State private var reportArtifact: ExportArtifact?
    @State private var previewReportArtifact: ExportArtifact?
    @State private var deletingEvidence: EvidenceItem?

    @Bindable var caseFile: CaseFile

    private var filteredItems: [EvidenceItem] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let scoped = caseFile.evidenceList.filter { item in
            guard !needle.isEmpty else { return true }
            return item.title.localizedCaseInsensitiveContains(needle)
                || item.note.localizedCaseInsensitiveContains(needle)
                || item.tags.localizedCaseInsensitiveContains(needle)
                || item.recognizedText.localizedCaseInsensitiveContains(needle)
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
                CaseSummaryHeader(
                    caseFile: caseFile,
                    hasFullAccess: purchaseService.hasFullAccess
                )
            }
            .listRowBackground(caseFile.category.tintColor.opacity(0.08))

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
                    EmptyTimelineView(color: caseFile.category.tintColor)
                } else {
                    ForEach(filteredItems) { item in
                        NavigationLink {
                            EvidenceDetailView(evidence: item)
                        } label: {
                            EvidenceRow(item: item, searchText: searchText)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deletingEvidence = item
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
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
                        ImportActionLabel(
                            title: L10n.text("Share Export Folder"),
                            systemName: "square.and.arrow.up",
                            color: .green
                        )
                    }
                }
            }

            if let artifact = reportArtifact {
                Section("Latest PDF Report") {
                    Text(artifact.url.lastPathComponent)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button {
                        previewReportArtifact = artifact
                    } label: {
                        ImportActionLabel(
                            title: L10n.text("Preview PDF Report"),
                            systemName: "eye",
                            color: .indigo
                        )
                    }

                    ShareLink(item: artifact.url) {
                        ImportActionLabel(
                            title: L10n.text("Share PDF Report"),
                            systemName: "doc.richtext",
                            color: .blue
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .evidenceScreenBackground()
        .navigationTitle(caseFile.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search title, note, tags, recognized text")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button {
                        exportCaseReport()
                    } label: {
                        Label(L10n.text("PDF Report"), systemImage: "doc.richtext")
                    }

                    Button {
                        exportCase()
                    } label: {
                        Label(L10n.text("Structured Archive"), systemImage: "archivebox")
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }

                Button {
                    if FreeUsageLimits.canAddEvidence(
                        currentEvidenceCount: caseFile.evidenceCount,
                        adding: 1,
                        hasFullAccess: purchaseService.hasFullAccess
                    ) {
                        showingAddEvidence = true
                    } else {
                        showingPaywall = true
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddEvidence) {
            AddEvidenceView(caseFile: caseFile)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(item: $previewReportArtifact) { artifact in
            QuickLookPreview(url: artifact.url)
        }
        .alert("Delete evidence?", isPresented: Binding(
            get: { deletingEvidence != nil },
            set: { if !$0 { deletingEvidence = nil } }
        )) {
            Button("Delete", role: .destructive) {
                guard let deletingEvidence else { return }
                do {
                    try store.deleteEvidence(deletingEvidence, context: modelContext)
                } catch {
                    store.lastError = error.localizedDescription
                }
                self.deletingEvidence = nil
            }
            Button("Cancel", role: .cancel) {
                deletingEvidence = nil
            }
        } message: {
            Text("This removes the evidence item and its stored file.")
        }
    }

    private func exportCase() {
        if let url = store.exportCase(caseFile) {
            exportArtifact = ExportArtifact(url: url)
        }
    }

    private func exportCaseReport() {
        if let url = store.exportCaseReport(caseFile) {
            let artifact = ExportArtifact(url: url)
            reportArtifact = artifact
            previewReportArtifact = artifact
        }
    }
}

private struct CaseSummaryHeader: View {
    let caseFile: CaseFile
    let hasFullAccess: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconBadge(
                systemName: caseFile.category.iconName,
                color: caseFile.category.tintColor,
                size: 52
            )

            VStack(alignment: .leading, spacing: 8) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        summaryBadges
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        summaryBadges
                    }
                }

                if !caseFile.notes.isEmpty {
                    Text(caseFile.notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var summaryBadges: some View {
        CapsuleBadge(
            caseFile.category.localizedTitle,
            color: caseFile.category.tintColor
        )
        CapsuleBadge(
            L10n.format("%lld items", Int64(caseFile.evidenceCount)),
            systemName: "doc",
            color: .blue
        )
        if FreeUsageLimits.isEnabled && !hasFullAccess {
            CapsuleBadge(
                L10n.format(
                    "Free %lld/%lld",
                    Int64(caseFile.evidenceCount),
                    Int64(FreeUsageLimits.maxEvidenceItemsPerCase)
                ),
                systemName: "lock",
                color: .orange
            )
        }
    }
}

private struct EmptyTimelineView: View {
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(systemName: "tray", color: color, size: 38)
            Text("No evidence items yet.")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

private struct EvidenceRow: View {
    let item: EvidenceItem
    let searchText: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            EvidenceThumbnailView(evidence: item, size: 52)

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer(minLength: 10)
                    Text(item.eventDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        evidenceBadges
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        evidenceBadges
                    }
                }

                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if let recognizedTextSnippet = item.recognizedText.localizedSnippet(matching: searchText) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(L10n.text("Recognized text match"), systemImage: "text.viewfinder")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.indigo)
                        Text(recognizedTextSnippet)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var evidenceBadges: some View {
        CapsuleBadge(
            item.evidenceType.displayName,
            color: item.evidenceType.tintColor
        )
        CapsuleBadge(
            ByteCountFormatter.string(fromByteCount: item.fileSize, countStyle: .file),
            systemName: "externaldrive",
            color: .secondary
        )
        CapsuleBadge(
            L10n.text("SHA-256 saved"),
            systemName: "checkmark.shield",
            color: .green
        )
        if !item.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            CapsuleBadge(
                L10n.text("Text recognized"),
                systemName: "text.viewfinder",
                color: .indigo
            )
        }
    }
}

private extension String {
    func localizedSnippet(matching query: String, contextCharacters: Int = 70) -> String? {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty,
              let range = range(
                of: trimmedQuery,
                options: [.caseInsensitive, .diacriticInsensitive]
              ) else {
            return nil
        }

        let lowerBound = index(
            range.lowerBound,
            offsetBy: -contextCharacters,
            limitedBy: startIndex
        ) ?? startIndex
        let upperBound = index(
            range.upperBound,
            offsetBy: contextCharacters,
            limitedBy: endIndex
        ) ?? endIndex

        let rawSnippet = String(self[lowerBound..<upperBound])
        let cleanedSnippet = rawSnippet
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")

        let prefix = lowerBound == startIndex ? "" : "... "
        let suffix = upperBound == endIndex ? "" : " ..."
        return prefix + cleanedSnippet + suffix
    }
}
