import Foundation

final class ChatStore: ObservableObject {
    @Published private(set) var summaries: [ChatSummary] = [.sample]
    @Published var importNotice: String?

    func handleImportResult(_ result: Result<[URL], any Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                importNotice = "Keine Datei ausgewählt."
                return
            }

            importFile(from: url)

        case .failure(let error):
            importNotice = error.localizedDescription
        }
    }

    private func importFile(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let ext = url.pathExtension.lowercased()

            if ext == "zip" {
                let summary = ChatSummary(
                    title: url.deletingPathExtension().lastPathComponent,
                    participantCount: 0,
                    messageCount: 0,
                    sourceKind: .zip,
                    previews: []
                )
                summaries.insert(summary, at: 0)
                importNotice = "ZIP-Import angelegt. Extraktion folgt im nächsten Schritt."
                return
            }

            let text = try loadText(from: url)
            let summary = WhatsAppTextParser.parse(text, title: url.deletingPathExtension().lastPathComponent)
            summaries.insert(summary, at: 0)
            importNotice = "\(summary.messageCount) Nachrichten aus \(summary.title) importiert."
        } catch {
            importNotice = "Import fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    private func loadText(from url: URL) throws -> String {
        let data = try Data(contentsOf: url)

        if let text = String(data: data, encoding: .utf8) {
            return text
        }

        if let text = String(data: data, encoding: .utf16) {
            return text
        }

        return String(decoding: data, as: UTF8.self)
    }
}

