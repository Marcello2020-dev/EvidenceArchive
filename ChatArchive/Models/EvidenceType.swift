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
            return "PDF"
        case .image:
            return "Image"
        case .audio:
            return "Audio"
        case .video:
            return "Video"
        case .text:
            return "Text"
        case .zip:
            return "ZIP"
        case .webLink:
            return "Web Link"
        case .other:
            return "Other"
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
