import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var store = ChatStore()
    @State private var searchText = ""
    @State private var isImporterPresented = false

    private var filteredSummaries: [ChatSummary] {
        store.summaries.filter { summary in
            searchText.isEmpty || summary.matches(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    importPanel
                }

                Section("Archive") {
                    if filteredSummaries.isEmpty {
                        ContentUnavailableView(
                            "Keine Chats",
                            systemImage: "text.bubble",
                            description: Text("Importiere einen Chat-Export oder passe die Suche an.")
                        )
                    } else {
                        ForEach(filteredSummaries) { summary in
                            NavigationLink(value: summary) {
                                ChatSummaryRow(summary: summary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Chat Archive")
            .searchable(text: $searchText, prompt: "Chats durchsuchen")
            .navigationDestination(for: ChatSummary.self) { summary in
                ChatDetailView(summary: summary)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isImporterPresented = true
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .fileImporter(
                isPresented: $isImporterPresented,
                allowedContentTypes: [.plainText, .zip],
                allowsMultipleSelection: false
            ) { result in
                store.handleImportResult(result)
            }
        }
    }

    private var importPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "archivebox")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .frame(width: 36, height: 36)
                    .background(.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text("WhatsApp-Export importieren")
                        .font(.headline)
                    Text(".txt wird rudimentar gelesen, .zip ist vorbereitet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                isImporterPresented = true
            } label: {
                Label("Datei auswählen", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            if let notice = store.importNotice {
                Text(notice)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

private struct ChatSummaryRow: View {
    let summary: ChatSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(summary.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(summary.sourceKind.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.12), in: Capsule())
            }

            HStack(spacing: 14) {
                Label("\(summary.messageCount)", systemImage: "bubble.left.and.bubble.right")
                Label("\(summary.participantCount)", systemImage: "person.2")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let preview = summary.previews.first {
                Text("\(preview.sender): \(preview.text)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct ChatDetailView: View {
    let summary: ChatSummary

    var body: some View {
        List {
            Section("Übersicht") {
                LabeledContent("Nachrichten", value: "\(summary.messageCount)")
                LabeledContent("Teilnehmer", value: "\(summary.participantCount)")
                LabeledContent("Quelle", value: summary.sourceKind.label)
            }

            Section("Vorschau") {
                if summary.previews.isEmpty {
                    ContentUnavailableView(
                        "Keine Nachrichten",
                        systemImage: "bubble.left",
                        description: Text("Für ZIP-Dateien ist die Extraktion noch nicht implementiert.")
                    )
                } else {
                    ForEach(summary.previews) { preview in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preview.sender)
                                .font(.subheadline.weight(.semibold))
                            Text(preview.text)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(summary.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}

