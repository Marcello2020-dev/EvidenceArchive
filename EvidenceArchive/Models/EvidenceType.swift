import Foundation
import UniformTypeIdentifiers

enum EvidenceType: String, Codable, CaseIterable, Identifiable {
    case pdf
    case image
    case audio
    case video
    case text
    case zip
    case webLink
    case other

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .pdf, .text:
            return "doc.text"
        case .image:
            return "photo"
        case .audio:
            return "waveform"
        case .video:
            return "video"
        case .zip:
            return "archivebox"
        case .webLink:
            return "link"
        case .other:
            return "doc"
        }
    }

    var displayName: String {
        switch self {
        case .pdf:
            return L10n.text("PDF")
        case .image:
            return L10n.text("Image")
        case .audio:
            return L10n.text("Audio")
        case .video:
            return L10n.text("Video")
        case .text:
            return L10n.text("Text")
        case .zip:
            return L10n.text("ZIP")
        case .webLink:
            return L10n.text("Web Link")
        case .other:
            return L10n.text("Other")
        }
    }

    static func infer(from typeIdentifier: String?) -> EvidenceType {
        guard let typeIdentifier,
              let type = UTType(typeIdentifier) else {
            return .other
        }

        if type.conforms(to: .pdf) { return .pdf }
        if type.conforms(to: .image) { return .image }
        if type.conforms(to: .audio) { return .audio }
        if type.conforms(to: .video) { return .video }
        if type.conforms(to: .plainText) || type.conforms(to: .text) { return .text }
        if type.conforms(to: .zip) || type.conforms(to: .archive) { return .zip }

        return .other
    }
}
