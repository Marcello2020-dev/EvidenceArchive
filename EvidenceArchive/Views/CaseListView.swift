import SwiftData
import SwiftUI

struct CaseListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var store: EvidenceStore
    @EnvironmentObject private var purchaseService: PurchaseService

    @Query(sort: [SortDescriptor(\CaseFile.updatedAt, order: .reverse)])
    private var cases: [CaseFile]

    @State private var showingNewCase = false
    @State private var showingPaywall = false
    @State private var editingCase: CaseFile?
    @State private var deletingCase: CaseFile?

    var body: some View {
        NavigationStack {
            Group {
                if cases.isEmpty {
                    EmptyCasesView()
                } else {
                    List {
                        ForEach(cases) { caseFile in
                            NavigationLink {
                                CaseDetailView(caseFile: caseFile)
                            } label: {
                                CaseRow(caseFile: caseFile)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deletingCase = caseFile
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    editingCase = caseFile
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Evidence Archive")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if FreeUsageLimits.canCreateCase(
                            currentCaseCount: cases.count,
                            hasFullAccess: purchaseService.hasFullAccess
                        ) {
                            showingNewCase = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Label("New Case", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewCase) {
                CaseEditorView(mode: .create)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(item: $editingCase) { caseFile in
                CaseEditorView(mode: .edit(caseFile))
            }
            .alert("Delete case?", isPresented: Binding(
                get: { deletingCase != nil },
                set: { if !$0 { deletingCase = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    guard let deletingCase else { return }
                    do {
                        try store.deleteCase(deletingCase, context: modelContext)
                    } catch {
                        store.lastError = error.localizedDescription
                    }
                    self.deletingCase = nil
                }
                Button("Cancel", role: .cancel) {
                    deletingCase = nil
                }
            } message: {
                Text("This also removes all evidence items in the case.")
            }
            .overlay(alignment: .bottom) {
                if let message = store.lastMessage {
                    ToastBanner(text: message)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                if store.lastMessage == message {
                                    store.lastMessage = nil
                                }
                            }
                        }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { store.lastError != nil },
                set: { if !$0 { store.lastError = nil } }
            )) {
                Button("OK", role: .cancel) {
                    store.lastError = nil
                }
            } message: {
                Text(store.lastError ?? L10n.text("Unknown error"))
            }
        }
    }
}

private struct CaseRow: View {
    let caseFile: CaseFile

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconBadge(
                systemName: caseFile.category.iconName,
                color: caseFile.category.tintColor,
                size: 46
            )

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(caseFile.title)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer(minLength: 10)
                    CapsuleBadge(
                        caseFile.category.localizedTitle,
                        color: caseFile.category.tintColor
                    )
                }

                Text(caseFile.notes.isEmpty ? L10n.text("No notes") : caseFile.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        caseStats
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        caseStats
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var caseStats: some View {
        CapsuleBadge(
            "\(caseFile.evidenceItems.count)",
            systemName: "doc",
            color: .blue
        )
        CapsuleBadge(
            caseFile.updatedAt.formatted(date: .abbreviated, time: .shortened),
            systemName: "clock",
            color: .secondary
        )
    }
}

private struct EmptyCasesView: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                IconBadge(systemName: "folder", color: .indigo, size: 78)
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.green)
                    .background(.background, in: Circle())
                    .offset(x: 6, y: 6)
            }

            VStack(spacing: 6) {
                Text("No case files yet")
                    .font(.title3.weight(.semibold))
                Text("Create your first archive to collect documents, screenshots, PDFs and notes.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 330)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

private struct ToastBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: Capsule())
            .padding(.bottom, 12)
    }
}

enum CaseEditorMode {
    case create
    case edit(CaseFile)
}

struct CaseEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var store: EvidenceStore

    let mode: CaseEditorMode

    @State private var title: String = ""
    @State private var category: CaseCategory = .privateCase
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Case") {
                    TextField("Title", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(CaseCategory.allCases) { category in
                            Label(category.localizedTitle, systemImage: category.iconName)
                                .tag(category)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle(titleText)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
            .onAppear(perform: fillDraft)
        }
    }

    private var titleText: String {
        switch mode {
        case .create:
            return L10n.text("New Case")
        case .edit:
            return L10n.text("Edit Case")
        }
    }

    private func fillDraft() {
        guard case .edit(let caseFile) = mode else { return }
        title = caseFile.title
        category = caseFile.category
        notes = caseFile.notes
    }

    private func save() {
        do {
            switch mode {
            case .create:
                try store.createCase(title: title, category: category, notes: notes, context: modelContext)
            case .edit(let caseFile):
                try store.updateCase(caseFile, title: title, category: category, notes: notes, context: modelContext)
            }
            dismiss()
        } catch {
            store.lastError = error.localizedDescription
        }
    }
}
