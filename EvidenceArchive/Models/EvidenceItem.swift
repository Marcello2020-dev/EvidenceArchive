import Foundation
import SwiftData

@Model
final class EvidenceItem {
    var id: UUID = UUID()
    var caseID: UUID = UUID()
    var title: String = ""
    var evidenceTypeRaw: String = EvidenceType.other.rawValue
    var originalFilename: String = ""
    var storedFilename: String = ""
    var eventDate: Date = Date()
    var importedAt: Date = Date()
    var source: String = ""
    var note: String = ""
    var tags: String = ""
    var recognizedText: String = ""
    var sha256: String = ""
    var fileSize: Int64 = 0
    var typeIdentifier: String = ""
    var relativeFilePath: String = ""

    var caseFile: CaseFile?

    init(
        id: UUID = UUID(),
        caseID: UUID,
        title: String,
        evidenceType: EvidenceType,
        originalFilename: String,
        storedFilename: String,
        eventDate: Date,
        importedAt: Date = .now,
        source: String,
        note: String,
        tags: String,
        recognizedText: String = "",
        sha256: String,
        fileSize: Int64,
        typeIdentifier: String,
        relativeFilePath: String,
        caseFile: CaseFile?
    ) {
        self.id = id
        self.caseID = caseID
        self.title = title
        self.evidenceTypeRaw = evidenceType.rawValue
        self.originalFilename = originalFilename
        self.storedFilename = storedFilename
        self.eventDate = eventDate
        self.importedAt = importedAt
        self.source = source
        self.note = note
        self.tags = tags
        self.recognizedText = recognizedText
        self.sha256 = sha256
        self.fileSize = fileSize
        self.typeIdentifier = typeIdentifier
        self.relativeFilePath = relativeFilePath
        self.caseFile = caseFile
    }

    var evidenceType: EvidenceType {
        get { EvidenceType(rawValue: evidenceTypeRaw) ?? .other }
        set { evidenceTypeRaw = newValue.rawValue }
    }

    var tagList: [String] {
        tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
