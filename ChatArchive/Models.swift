import Foundation

enum ChatSourceKind: String, Codable, Hashable {
    case text
    case zip
    case sample

    var label: String {
        switch self {
        case .text:
            "TXT"
        case .zip:
            "ZIP"
        case .sample:
            "Demo"
        }
    }
}

struct MessagePreview: Identifiable, Codable, Hashable {
    let id = UUID()
    let sender: String
    let text: String

    enum CodingKeys: String, CodingKey {
        case sender
        case text
    }
}

struct ChatSummary: Identifiable, Codable, Hashable {
    let id = UUID()
    let title: String
    let participantCount: Int
    let messageCount: Int
    let sourceKind: ChatSourceKind
    let previews: [MessagePreview]

    enum CodingKeys: String, CodingKey {
        case title
        case participantCount
        case messageCount
        case sourceKind
        case previews
    }

    func matches(_ query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return true }

        if title.localizedCaseInsensitiveContains(needle) {
            return true
        }

        return previews.contains { preview in
            preview.sender.localizedCaseInsensitiveContains(needle)
                || preview.text.localizedCaseInsensitiveContains(needle)
        }
    }
}

extension ChatSummary {
    static let sample = ChatSummary(
        title: "Demo Chat",
        participantCount: 3,
        messageCount: 8,
        sourceKind: .sample,
        previews: [
            MessagePreview(sender: "Lisa", text: "Ich habe den Export gerade getestet."),
            MessagePreview(sender: "Marcel", text: "Perfekt, dann bauen wir als naechstes den ZIP-Import."),
            MessagePreview(sender: "Nina", text: "Die Suche sollte spaeter auch Mediennamen finden.")
        ]
    )
}

