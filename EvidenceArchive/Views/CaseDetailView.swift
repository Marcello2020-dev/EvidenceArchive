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

    @State private var searchText = ""
    @State private var sortMode: SortMode = .newest
    @State private var showingAddEvidence = false
    @State private var showingPaywall = false
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
                        ImportActionLabel(
                            title: L10n.text("Share Export Folder"),
                            systemName: "square.and.arrow.up",
                            color: .green
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
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
                    if FreeUsageLimits.canAddEvidence(
                        currentEvidenceCount: caseFile.evidenceItems.count,
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
    }

    private func exportCase() {
        if let url = store.exportCase(caseFile) {
            exportArtifact = ExportArtifact(url: url)
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
            L10n.format("%lld items", Int64(caseFile.evidenceItems.count)),
            systemName: "doc",
            color: .blue
        )
        if !hasFullAccess {
            CapsuleBadge(
                L10n.format(
                    "Free %lld/%lld",
                    Int64(caseFile.evidenceItems.count),
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
    }
}
