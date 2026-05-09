import Foundation

enum EvidenceError: LocalizedError {
    case invalidCaseTitle
    case importFailed(String)
    case unsupportedType
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .invalidCaseTitle:
            return "Please enter a case title."
        case .importFailed(let reason):
            return "Import failed: \(reason)"
        case .unsupportedType:
            return "Unsupported file type."
        case .fileNotFound:
            return "Stored file was not found."
        }
    }
}
