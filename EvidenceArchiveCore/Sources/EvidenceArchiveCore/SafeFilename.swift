import Foundation

public enum SafeFilename {
    private static let forbiddenScalars = CharacterSet(charactersIn: "\\/:*?\"<>|\n\r\t")

    public static func sanitizeStem(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "evidence" }

        let filtered = trimmed.unicodeScalars.map { scalar -> Character in
            forbiddenScalars.contains(scalar) ? "_" : Character(scalar)
        }

        let collapsed = String(filtered)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return collapsed.isEmpty ? "evidence" : collapsed
    }

    public static func splitFilename(_ filename: String) -> (stem: String, ext: String) {
        let url = URL(fileURLWithPath: filename)
        let stem = sanitizeStem(url.deletingPathExtension().lastPathComponent)
        let ext = url.pathExtension.trimmingCharacters(in: .whitespacesAndNewlines)
        return (stem, ext)
    }

    public static func datePrefix(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: date)
    }

    public static func makeStoredFilename(
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
