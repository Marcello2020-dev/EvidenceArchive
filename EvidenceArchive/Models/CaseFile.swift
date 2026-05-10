import Foundation
import SwiftData

@Model
final class CaseFile {
    var id: UUID = UUID()
    var title: String = ""
    var categoryRaw: String = CaseCategory.privateCase.rawValue
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var notes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \EvidenceItem.caseFile)
    var evidenceItems: [EvidenceItem]? = []

    init(
        id: UUID = UUID(),
        title: String,
        category: CaseCategory = .privateCase,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.categoryRaw = category.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notes = notes
    }

    var category: CaseCategory {
        get { CaseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var evidenceList: [EvidenceItem] {
        evidenceItems ?? []
    }

    var evidenceCount: Int {
        evidenceItems?.count ?? 0
    }
}
