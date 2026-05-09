import Foundation

enum WhatsAppTextParser {
    static func parse(_ text: String, title: String) -> ChatSummary {
        var participants = Set<String>()
        var previews: [MessagePreview] = []
        var messageCount = 0

        for line in text.components(separatedBy: .newlines) {
            guard let message = parseMessageLine(line) else {
                continue
            }

            participants.insert(message.sender)
            messageCount += 1

            if previews.count < 20 {
                previews.append(MessagePreview(sender: message.sender, text: message.text))
            }
        }

        return ChatSummary(
            title: title.isEmpty ? "Importierter Chat" : title,
            participantCount: participants.count,
            messageCount: messageCount,
            sourceKind: .text,
            previews: previews
        )
    }

    private static func parseMessageLine(_ line: String) -> (sender: String, text: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("["),
           let closeBracket = trimmed.firstIndex(of: "]") {
            let start = trimmed.index(after: closeBracket)
            return parseSenderAndText(String(trimmed[start...]))
        }

        if let range = trimmed.range(of: " - ") {
            return parseSenderAndText(String(trimmed[range.upperBound...]))
        }

        return nil
    }

    private static func parseSenderAndText(_ raw: String) -> (sender: String, text: String)? {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let colon = cleaned.firstIndex(of: ":") else { return nil }

        let sender = cleaned[..<colon].trimmingCharacters(in: .whitespacesAndNewlines)
        let textStart = cleaned.index(after: colon)
        let text = cleaned[textStart...].trimmingCharacters(in: .whitespacesAndNewlines)

        guard !sender.isEmpty, !text.isEmpty else { return nil }
        return (sender, text)
    }
}

