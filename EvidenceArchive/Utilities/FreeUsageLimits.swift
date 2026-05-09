import Foundation

enum FreeUsageLimits {
    static let maxCaseFiles = 2
    static let maxEvidenceItemsPerCase = 3

    static func canCreateCase(currentCaseCount: Int, hasFullAccess: Bool) -> Bool {
        hasFullAccess || currentCaseCount < maxCaseFiles
    }

    static func canAddEvidence(
        currentEvidenceCount: Int,
        adding newEvidenceCount: Int,
        hasFullAccess: Bool
    ) -> Bool {
        hasFullAccess || currentEvidenceCount + max(0, newEvidenceCount) <= maxEvidenceItemsPerCase
    }
}
