import Foundation

enum EvidenceError: LocalizedError {
    case invalidCaseTitle
    case importFailed(String)
    case deleteFailed(String)
    case unsupportedType
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .invalidCaseTitle:
            return L10n.text("Please enter a case title.")
        case .importFailed(let reason):
            return L10n.format("Import failed: %@", reason)
        case .deleteFailed(let reason):
            return L10n.format("Delete failed: %@", reason)
        case .unsupportedType:
            return L10n.text("Unsupported file type.")
        case .fileNotFound:
            return L10n.text("Stored file was not found.")
        }
    }
}
