import Foundation

enum SafeFilename {
    private static let forbiddenScalars = CharacterSet(charactersIn: "\\/:*?\"<>|\n\r\t")

    static func sanitizeStem(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = "evidence"
        guard !trimmed.isEmpty else { return fallback }

        let filtered = trimmed.unicodeScalars.map { scalar -> Character in
            if forbiddenScalars.contains(scalar) {
                return "_"
            }
            return Character(scalar)
        }

        let collapsed = String(filtered)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return collapsed.isEmpty ? fallback : collapsed
    }

    static func splitFilename(_ filename: String) -> (stem: String, ext: String) {
        let url = URL(fileURLWithPath: filename)
        let stem = sanitizeStem(url.deletingPathExtension().lastPathComponent)
        let ext = url.pathExtension.trimmingCharacters(in: .whitespacesAndNewlines)
        return (stem, ext)
    }

    static func datePrefix(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: date)
    }

    static func makeStoredFilename(
        originalFilename: String,
        eventDate: Date,
        existingNames: Set<String>
    ) -> String {
        let parts = splitFilename(originalFilename)
        let prefix = datePrefix(from: eventDate)
        let base = "\(prefix)_\(parts.stem)"

        func render(_ candidateBase: String) -> String {
            if parts.ext.isEmpty {
                return candidateBase
            }
            return "\(candidateBase).\(parts.ext.lowercased())"
        }

        let firstCandidate = render(base)
        if !existingNames.contains(firstCandidate.lowercased()) {
            return firstCandidate
        }

        var index = 2
        while true {
            let candidate = render("\(base)_\(index)")
            if !existingNames.contains(candidate.lowercased()) {
                return candidate
            }
            index += 1
        }
    }
}
