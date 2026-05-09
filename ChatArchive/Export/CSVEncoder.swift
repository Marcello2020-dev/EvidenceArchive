import Foundation

enum CSVEncoder {
    static func escape(_ value: String) -> String {
        let needsQuotes = value.contains(",") || value.contains("\n") || value.contains("\"")
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return needsQuotes ? "\"\(escaped)\"" : escaped
    }

    static func row(_ values: [String]) -> String {
        values.map { escape($0) }.joined(separator: ",")
    }
}
